// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:flutter_plugin_tools/src/test_command.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  group('$TestCommand', () {
    CommandRunner<TestCommand> runner;
    final RecordingProcessRunner processRunner = RecordingProcessRunner();

    setUp(() {
      initializeFakePackages();
      final TestCommand command = TestCommand(mockPackagesDir, mockFileSystem,
          processRunner: processRunner);

      runner = CommandRunner<Null>('test_test', 'Test for $TestCommand');
      runner.addCommand(command);
    });

    tearDown(() {
      cleanupPackages();
      processRunner.recordedCalls.clear();
    });

    test('runs flutter test on each plugin', () async {
      final Directory plugin1Dir =
          createFakePlugin('plugin1', withExtraFiles: <List<String>>[
        <String>['test', 'empty_test.dart'],
      ]);
      final Directory plugin2Dir =
          createFakePlugin('plugin2', withExtraFiles: <List<String>>[
        <String>['test', 'empty_test.dart'],
      ]);

      await runner.run(<String>['test']);

      expect(
        processRunner.recordedCalls,
        orderedEquals(<ProcessCall>[
          ProcessCall('flutter', <String>['test', '--color'], plugin1Dir.path),
          ProcessCall('flutter', <String>['test', '--color'], plugin2Dir.path),
        ]),
      );

      cleanupPackages();
    });

    test('skips testing plugins without test directory', () async {
      createFakePlugin('plugin1');
      final Directory plugin2Dir =
          createFakePlugin('plugin2', withExtraFiles: <List<String>>[
        <String>['test', 'empty_test.dart'],
      ]);

      await runner.run(<String>['test']);

      expect(
        processRunner.recordedCalls,
        orderedEquals(<ProcessCall>[
          ProcessCall('flutter', <String>['test', '--color'], plugin2Dir.path),
        ]),
      );

      cleanupPackages();
    });

    test('runs pub run test on non-Flutter packages', () async {
      final Directory plugin1Dir = createFakePlugin('plugin1',
          isFlutter: true,
          withExtraFiles: <List<String>>[
            <String>['test', 'empty_test.dart'],
          ]);
      final Directory plugin2Dir = createFakePlugin('plugin2',
          isFlutter: false,
          withExtraFiles: <List<String>>[
            <String>['test', 'empty_test.dart'],
          ]);

      await runner.run(<String>['test', '--enable-experiment=exp1']);

      expect(
        processRunner.recordedCalls,
        orderedEquals(<ProcessCall>[
          ProcessCall(
              'flutter',
              <String>['test', '--color', '--enable-experiment=exp1'],
              plugin1Dir.path),
          ProcessCall('pub', <String>['get'], plugin2Dir.path),
          ProcessCall(
              'pub',
              <String>['run', '--enable-experiment=exp1', 'test'],
              plugin2Dir.path),
        ]),
      );

      cleanupPackages();
    });

    test('runs on Chrome for web plugins', () async {
      final Directory pluginDir = createFakePlugin(
        'plugin',
        withExtraFiles: <List<String>>[
          <String>['test', 'empty_test.dart'],
        ],
        isFlutter: true,
        isWebPlugin: true,
      );

      await runner.run(<String>['test']);

      expect(
        processRunner.recordedCalls,
        orderedEquals(<ProcessCall>[
          ProcessCall('flutter',
              <String>['test', '--color', '--platform=chrome'], pluginDir.path),
        ]),
      );
    });

    test('enable-experiment flag', () async {
      final Directory plugin1Dir = createFakePlugin('plugin1',
          isFlutter: true,
          withExtraFiles: <List<String>>[
            <String>['test', 'empty_test.dart'],
          ]);
      final Directory plugin2Dir = createFakePlugin('plugin2',
          isFlutter: false,
          withExtraFiles: <List<String>>[
            <String>['test', 'empty_test.dart'],
          ]);

      await runner.run(<String>['test', '--enable-experiment=exp1']);

      expect(
        processRunner.recordedCalls,
        orderedEquals(<ProcessCall>[
          ProcessCall(
              'flutter',
              <String>['test', '--color', '--enable-experiment=exp1'],
              plugin1Dir.path),
          ProcessCall('pub', <String>['get'], plugin2Dir.path),
          ProcessCall(
              'pub',
              <String>['run', '--enable-experiment=exp1', 'test'],
              plugin2Dir.path),
        ]),
      );

      cleanupPackages();
    });
  });
}
