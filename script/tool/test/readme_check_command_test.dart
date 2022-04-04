// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_plugin_tools/src/common/core.dart';
import 'package:flutter_plugin_tools/src/common/plugin_utils.dart';
import 'package:flutter_plugin_tools/src/readme_check_command.dart';
import 'package:test/test.dart';

import 'mocks.dart';
import 'util.dart';

void main() {
  late CommandRunner<void> runner;
  late RecordingProcessRunner processRunner;
  late FileSystem fileSystem;
  late MockPlatform mockPlatform;
  late Directory packagesDir;

  setUp(() {
    fileSystem = MemoryFileSystem();
    mockPlatform = MockPlatform();
    packagesDir = fileSystem.currentDirectory.childDirectory('packages');
    createPackagesDirectory(parentDir: packagesDir.parent);
    processRunner = RecordingProcessRunner();
    final ReadmeCheckCommand command = ReadmeCheckCommand(
      packagesDir,
      processRunner: processRunner,
      platform: mockPlatform,
    );

    runner = CommandRunner<void>(
        'readme_check_command', 'Test for readme_check_command');
    runner.addCommand(command);
  });

  test('fails when README is missing', () async {
    createFakePackage('a_package', packagesDir);

    Error? commandError;
    final List<String> output = await runCapturingPrint(
        runner, <String>['readme-check'], errorHandler: (Error e) {
      commandError = e;
    });

    expect(commandError, isA<ToolExit>());
    expect(
      output,
      containsAllInOrder(<Matcher>[
        contains('Missing README.md'),
      ]),
    );
  });

  group('plugin OS support', () {
    test(
        'does not check support table for anything other than app-facing plugin packages',
        () async {
      const String federatedPluginName = 'a_federated_plugin';
      final Directory federatedDir =
          packagesDir.childDirectory(federatedPluginName);
      final List<Directory> packageDirectories = <Directory>[
        // A non-plugin package.
        createFakePackage('a_package', packagesDir),
        // Non-app-facing parts of a federated plugin.
        createFakePlugin(
            '${federatedPluginName}_platform_interface', federatedDir),
        createFakePlugin('${federatedPluginName}_android', federatedDir),
      ];

      for (final Directory package in packageDirectories) {
        package.childFile('README.md').writeAsStringSync('''
A very useful package.
''');
      }

      final List<String> output = await runCapturingPrint(runner, <String>[
        'readme-check',
      ]);

      expect(
        output,
        containsAll(<Matcher>[
          contains('Running for a_package...'),
          contains('Running for a_federated_plugin_platform_interface...'),
          contains('Running for a_federated_plugin_android...'),
          contains('No issues found!'),
        ]),
      );
    });

    test('fails when non-federated plugin is missing an OS support table',
        () async {
      final Directory pluginDir = createFakePlugin('a_plugin', packagesDir);

      pluginDir.childFile('README.md').writeAsStringSync('''
A very useful plugin.
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['readme-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('No OS support table found'),
        ]),
      );
    });

    test(
        'fails when app-facing part of a federated plugin is missing an OS support table',
        () async {
      final Directory pluginDir =
          createFakePlugin('a_plugin', packagesDir.childDirectory('a_plugin'));

      pluginDir.childFile('README.md').writeAsStringSync('''
A very useful plugin.
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['readme-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('No OS support table found'),
        ]),
      );
    });

    test('fails the OS support table is missing the header', () async {
      final Directory pluginDir = createFakePlugin('a_plugin', packagesDir);

      pluginDir.childFile('README.md').writeAsStringSync('''
A very useful plugin.

| **Support**    | SDK 21+ | iOS 10+* | [See `camera_web `][1] |
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['readme-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('OS support table does not have the expected header format'),
        ]),
      );
    });

    test('fails if the OS support table is missing a supported OS', () async {
      final Directory pluginDir = createFakePlugin(
        'a_plugin',
        packagesDir,
        platformSupport: <String, PlatformDetails>{
          platformAndroid: const PlatformDetails(PlatformSupport.inline),
          platformIOS: const PlatformDetails(PlatformSupport.inline),
          platformWeb: const PlatformDetails(PlatformSupport.inline),
        },
      );

      pluginDir.childFile('README.md').writeAsStringSync('''
A very useful plugin.

|                | Android | iOS      |
|----------------|---------|----------|
| **Support**    | SDK 21+ | iOS 10+* |
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['readme-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('  OS support table does not match supported platforms:\n'
              '    Actual:     android, ios, web\n'
              '    Documented: android, ios'),
          contains('Incorrect OS support table'),
        ]),
      );
    });

    test('fails if the OS support table lists an extra OS', () async {
      final Directory pluginDir = createFakePlugin(
        'a_plugin',
        packagesDir,
        platformSupport: <String, PlatformDetails>{
          platformAndroid: const PlatformDetails(PlatformSupport.inline),
          platformIOS: const PlatformDetails(PlatformSupport.inline),
        },
      );

      pluginDir.childFile('README.md').writeAsStringSync('''
A very useful plugin.

|                | Android | iOS      | Web                    |
|----------------|---------|----------|------------------------|
| **Support**    | SDK 21+ | iOS 10+* | [See `camera_web `][1] |
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['readme-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('  OS support table does not match supported platforms:\n'
              '    Actual:     android, ios\n'
              '    Documented: android, ios, web'),
          contains('Incorrect OS support table'),
        ]),
      );
    });

    test('fails if the OS support table has unexpected OS formatting',
        () async {
      final Directory pluginDir = createFakePlugin(
        'a_plugin',
        packagesDir,
        platformSupport: <String, PlatformDetails>{
          platformAndroid: const PlatformDetails(PlatformSupport.inline),
          platformIOS: const PlatformDetails(PlatformSupport.inline),
          platformMacOS: const PlatformDetails(PlatformSupport.inline),
          platformWeb: const PlatformDetails(PlatformSupport.inline),
        },
      );

      pluginDir.childFile('README.md').writeAsStringSync('''
A very useful plugin.

|                | android | ios      | MacOS | web                    |
|----------------|---------|----------|-------|------------------------|
| **Support**    | SDK 21+ | iOS 10+* | 10.11 | [See `camera_web `][1] |
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['readme-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('  Incorrect OS capitalization: android, ios, MacOS, web\n'
              '    Please use standard capitalizations: Android, iOS, macOS, Web\n'),
          contains('Incorrect OS support formatting'),
        ]),
      );
    });
  });
}
