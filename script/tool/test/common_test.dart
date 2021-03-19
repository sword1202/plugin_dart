// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:flutter_plugin_tools/src/common.dart';
import 'package:git/git.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  RecordingProcessRunner processRunner;
  CommandRunner runner;
  List<String> plugins;
  List<List<String>> gitDirCommands;
  String gitDiffResponse;

  setUp(() {
    gitDirCommands = <List<String>>[];
    gitDiffResponse = '';
    final MockGitDir gitDir = MockGitDir();
    when(gitDir.runCommand(any)).thenAnswer((Invocation invocation) {
      gitDirCommands.add(invocation.positionalArguments[0]);
      final MockProcessResult mockProcessResult = MockProcessResult();
      if (invocation.positionalArguments[0][0] == 'diff') {
        when<String>(mockProcessResult.stdout).thenReturn(gitDiffResponse);
      }
      return Future<ProcessResult>.value(mockProcessResult);
    });
    initializeFakePackages();
    processRunner = RecordingProcessRunner();
    plugins = [];
    final SamplePluginCommand samplePluginCommand = SamplePluginCommand(
      plugins,
      mockPackagesDir,
      mockFileSystem,
      processRunner: processRunner,
      gitDir: gitDir,
    );
    runner =
        CommandRunner<Null>('common_command', 'Test for common functionality');
    runner.addCommand(samplePluginCommand);
  });

  tearDown(() {
    mockPackagesDir.deleteSync(recursive: true);
  });

  test('all plugins from file system', () async {
    final Directory plugin1 = createFakePlugin('plugin1');
    final Directory plugin2 = createFakePlugin('plugin2');
    await runner.run(<String>['sample']);
    expect(plugins, unorderedEquals(<String>[plugin1.path, plugin2.path]));
  });

  test('exclude plugins when plugins flag is specified', () async {
    createFakePlugin('plugin1');
    final Directory plugin2 = createFakePlugin('plugin2');
    await runner.run(
        <String>['sample', '--plugins=plugin1,plugin2', '--exclude=plugin1']);
    expect(plugins, unorderedEquals(<String>[plugin2.path]));
  });

  test('exclude plugins when plugins flag isn\'t specified', () async {
    createFakePlugin('plugin1');
    createFakePlugin('plugin2');
    await runner.run(<String>['sample', '--exclude=plugin1,plugin2']);
    expect(plugins, unorderedEquals(<String>[]));
  });

  test('exclude federated plugins when plugins flag is specified', () async {
    createFakePlugin('plugin1', parentDirectoryName: 'federated');
    final Directory plugin2 = createFakePlugin('plugin2');
    await runner.run(<String>[
      'sample',
      '--plugins=federated/plugin1,plugin2',
      '--exclude=federated/plugin1'
    ]);
    expect(plugins, unorderedEquals(<String>[plugin2.path]));
  });

  test('exclude entire federated plugins when plugins flag is specified',
      () async {
    createFakePlugin('plugin1', parentDirectoryName: 'federated');
    final Directory plugin2 = createFakePlugin('plugin2');
    await runner.run(<String>[
      'sample',
      '--plugins=federated/plugin1,plugin2',
      '--exclude=federated'
    ]);
    expect(plugins, unorderedEquals(<String>[plugin2.path]));
  });

  group('test run-on-changed-packages', () {
    test('all plugins should be tested if there are no changes.', () async {
      final Directory plugin1 = createFakePlugin('plugin1');
      final Directory plugin2 = createFakePlugin('plugin2');
      await runner.run(
          <String>['sample', '--base-sha=master', '--run-on-changed-packages']);

      expect(plugins, unorderedEquals(<String>[plugin1.path, plugin2.path]));
    });

    test('all plugins should be tested if there are no plugin related changes.',
        () async {
      gitDiffResponse = ".cirrus";
      final Directory plugin1 = createFakePlugin('plugin1');
      final Directory plugin2 = createFakePlugin('plugin2');
      await runner.run(
          <String>['sample', '--base-sha=master', '--run-on-changed-packages']);

      expect(plugins, unorderedEquals(<String>[plugin1.path, plugin2.path]));
    });

    test('Only changed plugin should be tested.', () async {
      gitDiffResponse = "packages/plugin1/plugin1.dart";
      final Directory plugin1 = createFakePlugin('plugin1');
      createFakePlugin('plugin2');
      await runner.run(
          <String>['sample', '--base-sha=master', '--run-on-changed-packages']);

      expect(plugins, unorderedEquals(<String>[plugin1.path]));
    });

    test('multiple files in one plugin should also test the plugin', () async {
      gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin1/ios/plugin1.m
''';
      final Directory plugin1 = createFakePlugin('plugin1');
      createFakePlugin('plugin2');
      await runner.run(
          <String>['sample', '--base-sha=master', '--run-on-changed-packages']);

      expect(plugins, unorderedEquals(<String>[plugin1.path]));
    });

    test('multiple plugins changed should test all the changed plugins',
        () async {
      gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin2/ios/plugin2.m
''';
      final Directory plugin1 = createFakePlugin('plugin1');
      final Directory plugin2 = createFakePlugin('plugin2');
      createFakePlugin('plugin3');
      await runner.run(
          <String>['sample', '--base-sha=master', '--run-on-changed-packages']);

      expect(plugins, unorderedEquals(<String>[plugin1.path, plugin2.path]));
    });

    test(
        'multiple plugins inside the same plugin group changed should output the plugin group name',
        () async {
      gitDiffResponse = '''
packages/plugin1/plugin1/plugin1.dart
packages/plugin1/plugin1_platform_interface/plugin1_platform_interface.dart
packages/plugin1/plugin1_web/plugin1_web.dart
''';
      final Directory plugin1 =
          createFakePlugin('plugin1', parentDirectoryName: 'plugin1');
      createFakePlugin('plugin2');
      createFakePlugin('plugin3');
      await runner.run(
          <String>['sample', '--base-sha=master', '--run-on-changed-packages']);

      expect(plugins, unorderedEquals(<String>[plugin1.path]));
    });

    test('--plugins flag overrides the behavior of --run-on-changed-packages',
        () async {
      gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin2/ios/plugin2.m
packages/plugin3/plugin3.dart
''';
      final Directory plugin1 =
          createFakePlugin('plugin1', parentDirectoryName: 'plugin1');
      final Directory plugin2 = createFakePlugin('plugin2');
      createFakePlugin('plugin3');
      await runner.run(<String>[
        'sample',
        '--plugins=plugin1,plugin2',
        '--base-sha=master',
        '--run-on-changed-packages'
      ]);

      expect(plugins, unorderedEquals(<String>[plugin1.path, plugin2.path]));
    });

    test('--exclude flag works with --run-on-changed-packages', () async {
      gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin2/ios/plugin2.m
packages/plugin3/plugin3.dart
''';
      final Directory plugin1 =
          createFakePlugin('plugin1', parentDirectoryName: 'plugin1');
      createFakePlugin('plugin2');
      createFakePlugin('plugin3');
      await runner.run(<String>[
        'sample',
        '--exclude=plugin2,plugin3',
        '--base-sha=master',
        '--run-on-changed-packages'
      ]);

      expect(plugins, unorderedEquals(<String>[plugin1.path]));
    });
  });

  group('$GitVersionFinder', () {
    List<List<String>> gitDirCommands;
    String gitDiffResponse;
    String mergeBaseResponse;
    MockGitDir gitDir;

    setUp(() {
      gitDirCommands = <List<String>>[];
      gitDiffResponse = '';
      gitDir = MockGitDir();
      when(gitDir.runCommand(any)).thenAnswer((Invocation invocation) {
        gitDirCommands.add(invocation.positionalArguments[0]);
        final MockProcessResult mockProcessResult = MockProcessResult();
        if (invocation.positionalArguments[0][0] == 'diff') {
          when<String>(mockProcessResult.stdout).thenReturn(gitDiffResponse);
        } else if (invocation.positionalArguments[0][0] == 'merge-base') {
          when<String>(mockProcessResult.stdout).thenReturn(mergeBaseResponse);
        }
        return Future<ProcessResult>.value(mockProcessResult);
      });
      initializeFakePackages();
      processRunner = RecordingProcessRunner();
    });

    tearDown(() {
      cleanupPackages();
    });

    test('No git diff should result no files changed', () async {
      final GitVersionFinder finder = GitVersionFinder(gitDir, 'some base sha');
      List<String> changedFiles = await finder.getChangedFiles();

      expect(changedFiles, isEmpty);
    });

    test('get correct files changed based on git diff', () async {
      gitDiffResponse = '''
file1/file1.cc
file2/file2.cc
''';
      final GitVersionFinder finder = GitVersionFinder(gitDir, 'some base sha');
      List<String> changedFiles = await finder.getChangedFiles();

      expect(
          changedFiles, equals(<String>['file1/file1.cc', 'file2/file2.cc']));
    });

    test('get correct pubspec change based on git diff', () async {
      gitDiffResponse = '''
file1/pubspec.yaml
file2/file2.cc
''';
      final GitVersionFinder finder = GitVersionFinder(gitDir, 'some base sha');
      List<String> changedFiles = await finder.getChangedPubSpecs();

      expect(changedFiles, equals(<String>['file1/pubspec.yaml']));
    });

    test('use correct base sha if not specified', () async {
      mergeBaseResponse = 'shaqwiueroaaidf12312jnadf123nd';
      gitDiffResponse = '''
file1/pubspec.yaml
file2/file2.cc
''';
      final GitVersionFinder finder = GitVersionFinder(gitDir, null);
      await finder.getChangedFiles();
      verify(gitDir
          .runCommand(['diff', '--name-only', mergeBaseResponse, 'HEAD']));
    });

    test('use correct base sha if specified', () async {
      final String customBaseSha = 'aklsjdcaskf12312';
      gitDiffResponse = '''
file1/pubspec.yaml
file2/file2.cc
''';
      final GitVersionFinder finder = GitVersionFinder(gitDir, customBaseSha);
      await finder.getChangedFiles();
      verify(gitDir.runCommand(['diff', '--name-only', customBaseSha, 'HEAD']));
    });
  });
}

class SamplePluginCommand extends PluginCommand {
  SamplePluginCommand(
    this.plugins_,
    Directory packagesDir,
    FileSystem fileSystem, {
    ProcessRunner processRunner = const ProcessRunner(),
    GitDir gitDir,
  }) : super(packagesDir, fileSystem,
            processRunner: processRunner, gitDir: gitDir);

  List<String> plugins_;

  @override
  final String name = 'sample';

  @override
  final String description = 'sample command';

  @override
  Future<Null> run() async {
    await for (Directory package in getPlugins()) {
      this.plugins_.add(package.path);
    }
  }
}

class MockGitDir extends Mock implements GitDir {}

class MockProcessResult extends Mock implements ProcessResult {}
