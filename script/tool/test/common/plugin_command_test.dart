// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_plugin_tools/src/common/plugin_command.dart';
import 'package:flutter_plugin_tools/src/common/process_runner.dart';
import 'package:git/git.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

import '../mocks.dart';
import '../util.dart';
import 'plugin_command_test.mocks.dart';

@GenerateMocks(<Type>[GitDir])
void main() {
  late RecordingProcessRunner processRunner;
  late SamplePluginCommand command;
  late CommandRunner<void> runner;
  late FileSystem fileSystem;
  late MockPlatform mockPlatform;
  late Directory packagesDir;
  late Directory thirdPartyPackagesDir;
  late List<List<String>?> gitDirCommands;
  late String gitDiffResponse;

  setUp(() {
    fileSystem = MemoryFileSystem();
    mockPlatform = MockPlatform();
    packagesDir = createPackagesDirectory(fileSystem: fileSystem);
    thirdPartyPackagesDir = packagesDir.parent
        .childDirectory('third_party')
        .childDirectory('packages');

    gitDirCommands = <List<String>?>[];
    gitDiffResponse = '';
    final MockGitDir gitDir = MockGitDir();
    when(gitDir.runCommand(any, throwOnError: anyNamed('throwOnError')))
        .thenAnswer((Invocation invocation) {
      gitDirCommands.add(invocation.positionalArguments[0] as List<String>?);
      final MockProcessResult mockProcessResult = MockProcessResult();
      if (invocation.positionalArguments[0][0] == 'diff') {
        when<String?>(mockProcessResult.stdout as String?)
            .thenReturn(gitDiffResponse);
      }
      return Future<ProcessResult>.value(mockProcessResult);
    });
    processRunner = RecordingProcessRunner();
    command = SamplePluginCommand(
      packagesDir,
      processRunner: processRunner,
      platform: mockPlatform,
      gitDir: gitDir,
    );
    runner =
        CommandRunner<void>('common_command', 'Test for common functionality');
    runner.addCommand(command);
  });

  group('plugin iteration', () {
    test('all plugins from file system', () async {
      final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
      final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
      await runCapturingPrint(runner, <String>['sample']);
      expect(command.plugins,
          unorderedEquals(<String>[plugin1.path, plugin2.path]));
    });

    test('includes both plugins and packages', () async {
      final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
      final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
      final Directory package3 = createFakePackage('package3', packagesDir);
      final Directory package4 = createFakePackage('package4', packagesDir);
      await runCapturingPrint(runner, <String>['sample']);
      expect(
          command.plugins,
          unorderedEquals(<String>[
            plugin1.path,
            plugin2.path,
            package3.path,
            package4.path,
          ]));
    });

    test('all plugins includes third_party/packages', () async {
      final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
      final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
      final Directory plugin3 =
          createFakePlugin('plugin3', thirdPartyPackagesDir);
      await runCapturingPrint(runner, <String>['sample']);
      expect(command.plugins,
          unorderedEquals(<String>[plugin1.path, plugin2.path, plugin3.path]));
    });

    test('--packages limits packages', () async {
      final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
      createFakePlugin('plugin2', packagesDir);
      createFakePackage('package3', packagesDir);
      final Directory package4 = createFakePackage('package4', packagesDir);
      await runCapturingPrint(
          runner, <String>['sample', '--packages=plugin1,package4']);
      expect(
          command.plugins,
          unorderedEquals(<String>[
            plugin1.path,
            package4.path,
          ]));
    });

    test('--plugins acts as an alias to --packages', () async {
      final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
      createFakePlugin('plugin2', packagesDir);
      createFakePackage('package3', packagesDir);
      final Directory package4 = createFakePackage('package4', packagesDir);
      await runCapturingPrint(
          runner, <String>['sample', '--plugins=plugin1,package4']);
      expect(
          command.plugins,
          unorderedEquals(<String>[
            plugin1.path,
            package4.path,
          ]));
    });

    test('exclude packages when packages flag is specified', () async {
      createFakePlugin('plugin1', packagesDir);
      final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
      await runCapturingPrint(runner, <String>[
        'sample',
        '--packages=plugin1,plugin2',
        '--exclude=plugin1'
      ]);
      expect(command.plugins, unorderedEquals(<String>[plugin2.path]));
    });

    test('exclude packages when packages flag isn\'t specified', () async {
      createFakePlugin('plugin1', packagesDir);
      createFakePlugin('plugin2', packagesDir);
      await runCapturingPrint(
          runner, <String>['sample', '--exclude=plugin1,plugin2']);
      expect(command.plugins, unorderedEquals(<String>[]));
    });

    test('exclude federated plugins when packages flag is specified', () async {
      createFakePlugin('plugin1', packagesDir.childDirectory('federated'));
      final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
      await runCapturingPrint(runner, <String>[
        'sample',
        '--packages=federated/plugin1,plugin2',
        '--exclude=federated/plugin1'
      ]);
      expect(command.plugins, unorderedEquals(<String>[plugin2.path]));
    });

    test('exclude entire federated plugins when packages flag is specified',
        () async {
      createFakePlugin('plugin1', packagesDir.childDirectory('federated'));
      final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
      await runCapturingPrint(runner, <String>[
        'sample',
        '--packages=federated/plugin1,plugin2',
        '--exclude=federated'
      ]);
      expect(command.plugins, unorderedEquals(<String>[plugin2.path]));
    });

    test('exclude accepts config files', () async {
      createFakePlugin('plugin1', packagesDir);
      final File configFile = packagesDir.childFile('exclude.yaml');
      configFile.writeAsStringSync('- plugin1');

      await runCapturingPrint(runner, <String>[
        'sample',
        '--packages=plugin1',
        '--exclude=${configFile.path}'
      ]);
      expect(command.plugins, unorderedEquals(<String>[]));
    });

    group('test run-on-changed-packages', () {
      test('all plugins should be tested if there are no changes.', () async {
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test(
          'all plugins should be tested if there are no plugin related changes.',
          () async {
        gitDiffResponse = 'AUTHORS';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('all plugins should be tested if .cirrus.yml changes.', () async {
        gitDiffResponse = '''
.cirrus.yml
packages/plugin1/CHANGELOG
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('all plugins should be tested if .ci.yaml changes', () async {
        gitDiffResponse = '''
.ci.yaml
packages/plugin1/CHANGELOG
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('all plugins should be tested if anything in .ci/ changes',
          () async {
        gitDiffResponse = '''
.ci/Dockerfile
packages/plugin1/CHANGELOG
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('all plugins should be tested if anything in script changes.',
          () async {
        gitDiffResponse = '''
script/tool_runner.sh
packages/plugin1/CHANGELOG
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('all plugins should be tested if the root analysis options change.',
          () async {
        gitDiffResponse = '''
analysis_options.yaml
packages/plugin1/CHANGELOG
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('all plugins should be tested if formatting options change.',
          () async {
        gitDiffResponse = '''
.clang-format
packages/plugin1/CHANGELOG
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('Only changed plugin should be tested.', () async {
        gitDiffResponse = 'packages/plugin1/plugin1.dart';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins, unorderedEquals(<String>[plugin1.path]));
      });

      test('multiple files in one plugin should also test the plugin',
          () async {
        gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin1/ios/plugin1.m
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        createFakePlugin('plugin2', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins, unorderedEquals(<String>[plugin1.path]));
      });

      test('multiple plugins changed should test all the changed plugins',
          () async {
        gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin2/ios/plugin2.m
''';
        final Directory plugin1 = createFakePlugin('plugin1', packagesDir);
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        createFakePlugin('plugin3', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
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
            createFakePlugin('plugin1', packagesDir.childDirectory('plugin1'));
        createFakePlugin('plugin2', packagesDir);
        createFakePlugin('plugin3', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins, unorderedEquals(<String>[plugin1.path]));
      });

      test(
          'changing one plugin in a federated group should include all plugins in the group',
          () async {
        gitDiffResponse = '''
packages/plugin1/plugin1/plugin1.dart
''';
        final Directory plugin1 =
            createFakePlugin('plugin1', packagesDir.childDirectory('plugin1'));
        final Directory plugin2 = createFakePlugin('plugin1_platform_interface',
            packagesDir.childDirectory('plugin1'));
        final Directory plugin3 = createFakePlugin(
            'plugin1_web', packagesDir.childDirectory('plugin1'));
        await runCapturingPrint(runner, <String>[
          'sample',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(
            command.plugins,
            unorderedEquals(
                <String>[plugin1.path, plugin2.path, plugin3.path]));
      });

      test(
          '--packages flag overrides the behavior of --run-on-changed-packages',
          () async {
        gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin2/ios/plugin2.m
packages/plugin3/plugin3.dart
''';
        final Directory plugin1 =
            createFakePlugin('plugin1', packagesDir.childDirectory('plugin1'));
        final Directory plugin2 = createFakePlugin('plugin2', packagesDir);
        createFakePlugin('plugin3', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--packages=plugin1,plugin2',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins,
            unorderedEquals(<String>[plugin1.path, plugin2.path]));
      });

      test('--exclude flag works with --run-on-changed-packages', () async {
        gitDiffResponse = '''
packages/plugin1/plugin1.dart
packages/plugin2/ios/plugin2.m
packages/plugin3/plugin3.dart
''';
        final Directory plugin1 =
            createFakePlugin('plugin1', packagesDir.childDirectory('plugin1'));
        createFakePlugin('plugin2', packagesDir);
        createFakePlugin('plugin3', packagesDir);
        await runCapturingPrint(runner, <String>[
          'sample',
          '--exclude=plugin2,plugin3',
          '--base-sha=master',
          '--run-on-changed-packages'
        ]);

        expect(command.plugins, unorderedEquals(<String>[plugin1.path]));
      });
    });
  });

  group('sharding', () {
    test('distributes evenly when evenly divisible', () async {
      final List<List<Directory>> expectedShards = <List<Directory>>[
        <Directory>[
          createFakePackage('package1', packagesDir),
          createFakePackage('package2', packagesDir),
          createFakePackage('package3', packagesDir),
        ],
        <Directory>[
          createFakePackage('package4', packagesDir),
          createFakePackage('package5', packagesDir),
          createFakePackage('package6', packagesDir),
        ],
        <Directory>[
          createFakePackage('package7', packagesDir),
          createFakePackage('package8', packagesDir),
          createFakePackage('package9', packagesDir),
        ],
      ];

      for (int i = 0; i < expectedShards.length; ++i) {
        final SamplePluginCommand localCommand = SamplePluginCommand(
          packagesDir,
          processRunner: processRunner,
          platform: mockPlatform,
          gitDir: MockGitDir(),
        );
        final CommandRunner<void> localRunner =
            CommandRunner<void>('common_command', 'Shard testing');
        localRunner.addCommand(localCommand);

        await runCapturingPrint(localRunner, <String>[
          'sample',
          '--shardIndex=$i',
          '--shardCount=3',
        ]);
        expect(
            localCommand.plugins,
            unorderedEquals(expectedShards[i]
                .map((Directory package) => package.path)
                .toList()));
      }
    });

    test('distributes as evenly as possible when not evenly divisible',
        () async {
      final List<List<Directory>> expectedShards = <List<Directory>>[
        <Directory>[
          createFakePackage('package1', packagesDir),
          createFakePackage('package2', packagesDir),
          createFakePackage('package3', packagesDir),
        ],
        <Directory>[
          createFakePackage('package4', packagesDir),
          createFakePackage('package5', packagesDir),
          createFakePackage('package6', packagesDir),
        ],
        <Directory>[
          createFakePackage('package7', packagesDir),
          createFakePackage('package8', packagesDir),
        ],
      ];

      for (int i = 0; i < expectedShards.length; ++i) {
        final SamplePluginCommand localCommand = SamplePluginCommand(
          packagesDir,
          processRunner: processRunner,
          platform: mockPlatform,
          gitDir: MockGitDir(),
        );
        final CommandRunner<void> localRunner =
            CommandRunner<void>('common_command', 'Shard testing');
        localRunner.addCommand(localCommand);

        await runCapturingPrint(localRunner, <String>[
          'sample',
          '--shardIndex=$i',
          '--shardCount=3',
        ]);
        expect(
            localCommand.plugins,
            unorderedEquals(expectedShards[i]
                .map((Directory package) => package.path)
                .toList()));
      }
    });

    // In CI (which is the use case for sharding) we often want to run muliple
    // commands on the same set of packages, but the exclusion lists for those
    // commands may be different. In those cases we still want all the commands
    // to operate on a consistent set of plugins.
    //
    // E.g., some commands require running build-examples in a previous step;
    // excluding some plugins from the later step shouldn't change what's tested
    // in each shard, as it may no longer align with what was built.
    test('counts excluded plugins when sharding', () async {
      final List<List<Directory>> expectedShards = <List<Directory>>[
        <Directory>[
          createFakePackage('package1', packagesDir),
          createFakePackage('package2', packagesDir),
          createFakePackage('package3', packagesDir),
        ],
        <Directory>[
          createFakePackage('package4', packagesDir),
          createFakePackage('package5', packagesDir),
          createFakePackage('package6', packagesDir),
        ],
        <Directory>[
          createFakePackage('package7', packagesDir),
        ],
      ];
      // These would be in the last shard, but are excluded.
      createFakePackage('package8', packagesDir);
      createFakePackage('package9', packagesDir);

      for (int i = 0; i < expectedShards.length; ++i) {
        final SamplePluginCommand localCommand = SamplePluginCommand(
          packagesDir,
          processRunner: processRunner,
          platform: mockPlatform,
          gitDir: MockGitDir(),
        );
        final CommandRunner<void> localRunner =
            CommandRunner<void>('common_command', 'Shard testing');
        localRunner.addCommand(localCommand);

        await runCapturingPrint(localRunner, <String>[
          'sample',
          '--shardIndex=$i',
          '--shardCount=3',
          '--exclude=package8,package9',
        ]);
        expect(
            localCommand.plugins,
            unorderedEquals(expectedShards[i]
                .map((Directory package) => package.path)
                .toList()));
      }
    });
  });
}

class SamplePluginCommand extends PluginCommand {
  SamplePluginCommand(
    Directory packagesDir, {
    ProcessRunner processRunner = const ProcessRunner(),
    Platform platform = const LocalPlatform(),
    GitDir? gitDir,
  }) : super(packagesDir,
            processRunner: processRunner, platform: platform, gitDir: gitDir);

  final List<String> plugins = <String>[];

  @override
  final String name = 'sample';

  @override
  final String description = 'sample command';

  @override
  Future<void> run() async {
    await for (final PackageEnumerationEntry package in getTargetPackages()) {
      plugins.add(package.directory.path);
    }
  }
}

class MockProcessResult extends Mock implements ProcessResult {}
