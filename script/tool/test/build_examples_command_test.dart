// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_plugin_tools/src/build_examples_command.dart';
import 'package:flutter_plugin_tools/src/common/core.dart';
import 'package:flutter_plugin_tools/src/common/plugin_utils.dart';
import 'package:test/test.dart';

import 'mocks.dart';
import 'util.dart';

void main() {
  group('build-example', () {
    late FileSystem fileSystem;
    late MockPlatform mockPlatform;
    late Directory packagesDir;
    late CommandRunner<void> runner;
    late RecordingProcessRunner processRunner;

    setUp(() {
      fileSystem = MemoryFileSystem();
      mockPlatform = MockPlatform();
      packagesDir = createPackagesDirectory(fileSystem: fileSystem);
      processRunner = RecordingProcessRunner();
      final BuildExamplesCommand command = BuildExamplesCommand(
        packagesDir,
        processRunner: processRunner,
        platform: mockPlatform,
      );

      runner = CommandRunner<void>(
          'build_examples_command', 'Test for build_example_command');
      runner.addCommand(command);
    });

    test('fails if no plaform flags are passed', () async {
      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
          output,
          containsAllInOrder(<Matcher>[
            contains('At least one platform must be provided'),
          ]));
    });

    test('fails if building fails', () async {
      createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformIos: PlatformSupport.inline
          });

      processRunner
              .mockProcessesForExecutable[getFlutterCommand(mockPlatform)] =
          <io.Process>[
        MockProcess.failing() // flutter packages get
      ];

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples', '--ios'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
          output,
          containsAllInOrder(<Matcher>[
            contains('The following packages had errors:'),
            contains('  plugin:\n'
                '    plugin/example (iOS)'),
          ]));
    });

    test('building for iOS when plugin is not set up for iOS results in no-op',
        () async {
      mockPlatform.isMacOS = true;
      createFakePlugin('plugin', packagesDir);

      final List<String> output =
          await runCapturingPrint(runner, <String>['build-examples', '--ios']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin'),
          contains('iOS is not supported by this plugin'),
        ]),
      );

      // Output should be empty since running build-examples --macos with no macos
      // implementation is a no-op.
      expect(processRunner.recordedCalls, orderedEquals(<ProcessCall>[]));
    });

    test('building for iOS', () async {
      mockPlatform.isMacOS = true;
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformIos: PlatformSupport.inline
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      final List<String> output = await runCapturingPrint(runner,
          <String>['build-examples', '--ios', '--enable-experiment=exp1']);

      expect(
        output,
        containsAllInOrder(<String>[
          '\nBUILDING plugin/example for iOS',
        ]),
      );

      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(
                getFlutterCommand(mockPlatform),
                const <String>[
                  'build',
                  'ios',
                  '--no-codesign',
                  '--enable-experiment=exp1'
                ],
                pluginExampleDirectory.path),
          ]));
    });

    test(
        'building for Linux when plugin is not set up for Linux results in no-op',
        () async {
      mockPlatform.isLinux = true;
      createFakePlugin('plugin', packagesDir);

      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples', '--linux']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin'),
          contains('Linux is not supported by this plugin'),
        ]),
      );

      // Output should be empty since running build-examples --linux with no
      // Linux implementation is a no-op.
      expect(processRunner.recordedCalls, orderedEquals(<ProcessCall>[]));
    });

    test('building for Linux', () async {
      mockPlatform.isLinux = true;
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformLinux: PlatformSupport.inline,
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples', '--linux']);

      expect(
        output,
        containsAllInOrder(<String>[
          '\nBUILDING plugin/example for Linux',
        ]),
      );

      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(getFlutterCommand(mockPlatform),
                const <String>['build', 'linux'], pluginExampleDirectory.path),
          ]));
    });

    test('building for macOS with no implementation results in no-op',
        () async {
      mockPlatform.isMacOS = true;
      createFakePlugin('plugin', packagesDir);

      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples', '--macos']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin'),
          contains('macOS is not supported by this plugin'),
        ]),
      );

      // Output should be empty since running build-examples --macos with no macos
      // implementation is a no-op.
      expect(processRunner.recordedCalls, orderedEquals(<ProcessCall>[]));
    });

    test('building for macOS', () async {
      mockPlatform.isMacOS = true;
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformMacos: PlatformSupport.inline,
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples', '--macos']);

      expect(
        output,
        containsAllInOrder(<String>[
          '\nBUILDING plugin/example for macOS',
        ]),
      );

      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(getFlutterCommand(mockPlatform),
                const <String>['build', 'macos'], pluginExampleDirectory.path),
          ]));
    });

    test('building for web with no implementation results in no-op', () async {
      createFakePlugin('plugin', packagesDir);

      final List<String> output =
          await runCapturingPrint(runner, <String>['build-examples', '--web']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin'),
          contains('web is not supported by this plugin'),
        ]),
      );

      // Output should be empty since running build-examples --macos with no macos
      // implementation is a no-op.
      expect(processRunner.recordedCalls, orderedEquals(<ProcessCall>[]));
    });

    test('building for web', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformWeb: PlatformSupport.inline,
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      final List<String> output =
          await runCapturingPrint(runner, <String>['build-examples', '--web']);

      expect(
        output,
        containsAllInOrder(<String>[
          '\nBUILDING plugin/example for web',
        ]),
      );

      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(getFlutterCommand(mockPlatform),
                const <String>['build', 'web'], pluginExampleDirectory.path),
          ]));
    });

    test(
        'building for Windows when plugin is not set up for Windows results in no-op',
        () async {
      mockPlatform.isWindows = true;
      createFakePlugin('plugin', packagesDir);

      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples', '--windows']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin'),
          contains('Windows is not supported by this plugin'),
        ]),
      );

      // Output should be empty since running build-examples --windows with no
      // Windows implementation is a no-op.
      expect(processRunner.recordedCalls, orderedEquals(<ProcessCall>[]));
    });

    test('building for Windows', () async {
      mockPlatform.isWindows = true;
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformWindows: PlatformSupport.inline
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      final List<String> output = await runCapturingPrint(
          runner, <String>['build-examples', '--windows']);

      expect(
        output,
        containsAllInOrder(<String>[
          '\nBUILDING plugin/example for Windows',
        ]),
      );

      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(
                getFlutterCommand(mockPlatform),
                const <String>['build', 'windows'],
                pluginExampleDirectory.path),
          ]));
    });

    test(
        'building for Android when plugin is not set up for Android results in no-op',
        () async {
      createFakePlugin('plugin', packagesDir);

      final List<String> output =
          await runCapturingPrint(runner, <String>['build-examples', '--apk']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin'),
          contains('Android is not supported by this plugin'),
        ]),
      );

      // Output should be empty since running build-examples --macos with no macos
      // implementation is a no-op.
      expect(processRunner.recordedCalls, orderedEquals(<ProcessCall>[]));
    });

    test('building for Android', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformAndroid: PlatformSupport.inline
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      final List<String> output = await runCapturingPrint(runner, <String>[
        'build-examples',
        '--apk',
      ]);

      expect(
        output,
        containsAllInOrder(<String>[
          '\nBUILDING plugin/example for Android (apk)',
        ]),
      );

      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(getFlutterCommand(mockPlatform),
                const <String>['build', 'apk'], pluginExampleDirectory.path),
          ]));
    });

    test('enable-experiment flag for Android', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformAndroid: PlatformSupport.inline
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      await runCapturingPrint(runner,
          <String>['build-examples', '--apk', '--enable-experiment=exp1']);

      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(
                getFlutterCommand(mockPlatform),
                const <String>['build', 'apk', '--enable-experiment=exp1'],
                pluginExampleDirectory.path),
          ]));
    });

    test('enable-experiment flag for ios', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir,
          platformSupport: <String, PlatformSupport>{
            kPlatformIos: PlatformSupport.inline
          });

      final Directory pluginExampleDirectory =
          pluginDirectory.childDirectory('example');

      await runCapturingPrint(runner,
          <String>['build-examples', '--ios', '--enable-experiment=exp1']);
      expect(
          processRunner.recordedCalls,
          orderedEquals(<ProcessCall>[
            ProcessCall(
                getFlutterCommand(mockPlatform),
                const <String>[
                  'build',
                  'ios',
                  '--no-codesign',
                  '--enable-experiment=exp1'
                ],
                pluginExampleDirectory.path),
          ]));
    });
  });
}
