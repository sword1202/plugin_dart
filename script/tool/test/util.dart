// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_plugin_tools/src/common/core.dart';
import 'package:flutter_plugin_tools/src/common/plugin_utils.dart';
import 'package:flutter_plugin_tools/src/common/process_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:quiver/collection.dart';

/// Returns the exe name that command will use when running Flutter on
/// [platform].
String getFlutterCommand(Platform platform) =>
    platform.isWindows ? 'flutter.bat' : 'flutter';

/// Creates a packages directory in the given location.
///
/// If [parentDir] is set the packages directory will be created there,
/// otherwise [fileSystem] must be provided and it will be created an arbitrary
/// location in that filesystem.
Directory createPackagesDirectory(
    {Directory? parentDir, FileSystem? fileSystem}) {
  assert(parentDir != null || fileSystem != null,
      'One of parentDir or fileSystem must be provided');
  assert(fileSystem == null || fileSystem is MemoryFileSystem,
      'If using a real filesystem, parentDir must be provided');
  final Directory packagesDir =
      (parentDir ?? fileSystem!.currentDirectory).childDirectory('packages');
  packagesDir.createSync();
  return packagesDir;
}

/// Creates a plugin package with the given [name] in [packagesDirectory].
///
/// [platformSupport] is a map of platform string to the support details for
/// that platform.
///
/// [extraFiles] is an optional list of plugin-relative paths, using Posix
/// separators, of extra files to create in the plugin.
Directory createFakePlugin(
  String name,
  Directory parentDirectory, {
  List<String> examples = const <String>['example'],
  List<String> extraFiles = const <String>[],
  Map<String, PlatformSupport> platformSupport =
      const <String, PlatformSupport>{},
  String? version = '0.0.1',
}) {
  final Directory pluginDirectory = createFakePackage(name, parentDirectory,
      isFlutter: true,
      examples: examples,
      extraFiles: extraFiles,
      version: version);

  createFakePubspec(
    pluginDirectory,
    name: name,
    isFlutter: true,
    isPlugin: true,
    platformSupport: platformSupport,
    version: version,
  );

  return pluginDirectory;
}

/// Creates a plugin package with the given [name] in [packagesDirectory].
///
/// [extraFiles] is an optional list of package-relative paths, using unix-style
/// separators, of extra files to create in the package.
Directory createFakePackage(
  String name,
  Directory parentDirectory, {
  List<String> examples = const <String>['example'],
  List<String> extraFiles = const <String>[],
  bool isFlutter = false,
  String? version = '0.0.1',
}) {
  final Directory packageDirectory = parentDirectory.childDirectory(name);
  packageDirectory.createSync(recursive: true);

  createFakePubspec(packageDirectory, name: name, isFlutter: isFlutter);
  createFakeCHANGELOG(packageDirectory, '''
## $version
  * Some changes.
  ''');

  if (examples.length == 1) {
    final Directory exampleDir = packageDirectory.childDirectory(examples.first)
      ..createSync();
    createFakePubspec(exampleDir,
        name: '${name}_example', isFlutter: isFlutter, publishTo: 'none');
  } else if (examples.isNotEmpty) {
    final Directory exampleDir = packageDirectory.childDirectory('example')
      ..createSync();
    for (final String example in examples) {
      final Directory currentExample = exampleDir.childDirectory(example)
        ..createSync();
      createFakePubspec(currentExample,
          name: example, isFlutter: isFlutter, publishTo: 'none');
    }
  }

  final FileSystem fileSystem = packageDirectory.fileSystem;
  final p.Context posixContext = p.posix;
  for (final String file in extraFiles) {
    final List<String> newFilePath = <String>[
      packageDirectory.path,
      ...posixContext.split(file)
    ];
    final File newFile = fileSystem.file(fileSystem.path.joinAll(newFilePath));
    newFile.createSync(recursive: true);
  }

  return packageDirectory;
}

void createFakeCHANGELOG(Directory parent, String texts) {
  parent.childFile('CHANGELOG.md').createSync();
  parent.childFile('CHANGELOG.md').writeAsStringSync(texts);
}

/// Creates a `pubspec.yaml` file with a flutter dependency.
///
/// [platformSupport] is a map of platform string to the support details for
/// that platform. If empty, no `plugin` entry will be created unless `isPlugin`
/// is set to `true`.
void createFakePubspec(
  Directory parent, {
  String name = 'fake_package',
  bool isFlutter = true,
  bool isPlugin = false,
  Map<String, PlatformSupport> platformSupport =
      const <String, PlatformSupport>{},
  String publishTo = 'http://no_pub_server.com',
  String? version,
}) {
  isPlugin |= platformSupport.isNotEmpty;
  parent.childFile('pubspec.yaml').createSync();
  String yaml = '''
name: $name
''';
  if (isFlutter) {
    if (isPlugin) {
      yaml += '''
flutter:
  plugin:
    platforms:
''';
      for (final MapEntry<String, PlatformSupport> platform
          in platformSupport.entries) {
        yaml += _pluginPlatformSection(platform.key, platform.value, name);
      }
    }

    yaml += '''
dependencies:
  flutter:
    sdk: flutter
''';
  }
  if (version != null) {
    yaml += '''
version: $version
''';
  }
  if (publishTo.isNotEmpty) {
    yaml += '''
publish_to: $publishTo # Hardcoded safeguard to prevent this from somehow being published by a broken test.
''';
  }
  parent.childFile('pubspec.yaml').writeAsStringSync(yaml);
}

String _pluginPlatformSection(
    String platform, PlatformSupport type, String packageName) {
  if (type == PlatformSupport.federated) {
    return '''
      $platform:
        default_package: ${packageName}_$platform
''';
  }
  switch (platform) {
    case kPlatformAndroid:
      return '''
      android:
        package: io.flutter.plugins.fake
        pluginClass: FakePlugin
''';
    case kPlatformIos:
      return '''
      ios:
        pluginClass: FLTFakePlugin
''';
    case kPlatformLinux:
      return '''
      linux:
        pluginClass: FakePlugin
''';
    case kPlatformMacos:
      return '''
      macos:
        pluginClass: FakePlugin
''';
    case kPlatformWeb:
      return '''
      web:
        pluginClass: FakePlugin
        fileName: ${packageName}_web.dart
''';
    case kPlatformWindows:
      return '''
      windows:
        pluginClass: FakePlugin
''';
    default:
      assert(false);
      return '';
  }
}

typedef _ErrorHandler = void Function(Error error);

/// Run the command [runner] with the given [args] and return
/// what was printed.
/// A custom [errorHandler] can be used to handle the runner error as desired without throwing.
Future<List<String>> runCapturingPrint(
    CommandRunner<void> runner, List<String> args,
    {_ErrorHandler? errorHandler}) async {
  final List<String> prints = <String>[];
  final ZoneSpecification spec = ZoneSpecification(
    print: (_, __, ___, String message) {
      prints.add(message);
    },
  );
  try {
    await Zone.current
        .fork(specification: spec)
        .run<Future<void>>(() => runner.run(args));
  } on Error catch (e) {
    if (errorHandler == null) {
      rethrow;
    }
    errorHandler(e);
  }

  return prints;
}

/// A mock [ProcessRunner] which records process calls.
class RecordingProcessRunner extends ProcessRunner {
  final List<ProcessCall> recordedCalls = <ProcessCall>[];

  /// Maps an executable to a list of processes that should be used for each
  /// successive call to it via [run], [runAndStream], or [start].
  final Map<String, List<io.Process>> mockProcessesForExecutable =
      <String, List<io.Process>>{};

  /// Populate for [io.ProcessResult] to use a String [stdout] instead of a [List] of [int].
  String? resultStdout;

  /// Populate for [io.ProcessResult] to use a String [stderr] instead of a [List] of [int].
  String? resultStderr;

  // Deprecated--do not add new uses. Use mockProcessesForExecutable instead.
  io.Process? processToReturn;

  @override
  Future<int> runAndStream(
    String executable,
    List<String> args, {
    Directory? workingDir,
    bool exitOnError = false,
  }) async {
    recordedCalls.add(ProcessCall(executable, args, workingDir?.path));
    final io.Process? processToReturn = _getProcessToReturn(executable);
    final int exitCode =
        processToReturn == null ? 0 : await processToReturn.exitCode;
    if (exitOnError && (exitCode != 0)) {
      throw io.ProcessException(executable, args);
    }
    return Future<int>.value(exitCode);
  }

  /// Returns [io.ProcessResult] created from [mockProcessesForExecutable],
  /// [resultStdout], and [resultStderr].
  @override
  Future<io.ProcessResult> run(
    String executable,
    List<String> args, {
    Directory? workingDir,
    bool exitOnError = false,
    bool logOnError = false,
    Encoding stdoutEncoding = io.systemEncoding,
    Encoding stderrEncoding = io.systemEncoding,
  }) async {
    recordedCalls.add(ProcessCall(executable, args, workingDir?.path));

    final io.Process? process = _getProcessToReturn(executable);
    final io.ProcessResult result = process == null
        ? io.ProcessResult(1, 0, '', '')
        : io.ProcessResult(process.pid, await process.exitCode,
            resultStdout ?? process.stdout, resultStderr ?? process.stderr);

    if (exitOnError && (result.exitCode != 0)) {
      throw io.ProcessException(executable, args);
    }

    return Future<io.ProcessResult>.value(result);
  }

  @override
  Future<io.Process> start(String executable, List<String> args,
      {Directory? workingDirectory}) async {
    recordedCalls.add(ProcessCall(executable, args, workingDirectory?.path));
    return Future<io.Process>.value(_getProcessToReturn(executable));
  }

  io.Process? _getProcessToReturn(String executable) {
    io.Process? process;
    final List<io.Process>? processes = mockProcessesForExecutable[executable];
    if (processes != null && processes.isNotEmpty) {
      process = mockProcessesForExecutable[executable]!.removeAt(0);
    }
    // Fall back to `processToReturn` for backwards compatibility.
    return process ?? processToReturn;
  }
}

/// A recorded process call.
@immutable
class ProcessCall {
  const ProcessCall(this.executable, this.args, this.workingDir);

  /// The executable that was called.
  final String executable;

  /// The arguments passed to [executable] in the call.
  final List<String> args;

  /// The working directory this process was called from.
  final String? workingDir;

  @override
  bool operator ==(dynamic other) {
    return other is ProcessCall &&
        executable == other.executable &&
        listsEqual(args, other.args) &&
        workingDir == other.workingDir;
  }

  @override
  int get hashCode =>
      (executable.hashCode) ^ (args.hashCode) ^ (workingDir?.hashCode ?? 0);

  @override
  String toString() {
    final List<String> command = <String>[executable, ...args];
    return '"${command.join(' ')}" in $workingDir';
  }
}
