import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_plugin_tools/src/common.dart';
import 'package:git/git.dart';
import 'package:mockito/mockito.dart';
import "package:test/test.dart";
import "package:flutter_plugin_tools/src/version_check_command.dart";
import 'package:pub_semver/pub_semver.dart';
import 'util.dart';

void testAllowedVersion(
  String masterVersion,
  String headVersion, {
  bool allowed = true,
  NextVersionType nextVersionType,
}) {
  final Version master = Version.parse(masterVersion);
  final Version head = Version.parse(headVersion);
  final Map<Version, NextVersionType> allowedVersions =
      getAllowedNextVersions(master, head);
  if (allowed) {
    expect(allowedVersions, contains(head));
    if (nextVersionType != null) {
      expect(allowedVersions[head], equals(nextVersionType));
    }
  } else {
    expect(allowedVersions, isNot(contains(head)));
  }
}

class MockGitDir extends Mock implements GitDir {}

class MockProcessResult extends Mock implements ProcessResult {}

void main() {
  group('$VersionCheckCommand', () {
    CommandRunner<VersionCheckCommand> runner;
    RecordingProcessRunner processRunner;
    List<List<String>> gitDirCommands;
    String gitDiffResponse;
    Map<String, String> gitShowResponses;

    setUp(() {
      gitDirCommands = <List<String>>[];
      gitDiffResponse = '';
      gitShowResponses = <String, String>{};
      final MockGitDir gitDir = MockGitDir();
      when(gitDir.runCommand(any)).thenAnswer((Invocation invocation) {
        gitDirCommands.add(invocation.positionalArguments[0]);
        final MockProcessResult mockProcessResult = MockProcessResult();
        if (invocation.positionalArguments[0][0] == 'diff') {
          when<String>(mockProcessResult.stdout).thenReturn(gitDiffResponse);
        } else if (invocation.positionalArguments[0][0] == 'show') {
          final String response =
              gitShowResponses[invocation.positionalArguments[0][1]];
          when<String>(mockProcessResult.stdout).thenReturn(response);
        }
        return Future<ProcessResult>.value(mockProcessResult);
      });
      initializeFakePackages();
      processRunner = RecordingProcessRunner();
      final VersionCheckCommand command = VersionCheckCommand(
          mockPackagesDir, mockFileSystem,
          processRunner: processRunner, gitDir: gitDir);

      runner = CommandRunner<Null>(
          'version_check_command', 'Test for $VersionCheckCommand');
      runner.addCommand(command);
    });

    tearDown(() {
      cleanupPackages();
    });

    test('allows valid version', () async {
      createFakePlugin('plugin', includeChangeLog: true, includeVersion: true);
      gitDiffResponse = "packages/plugin/pubspec.yaml";
      gitShowResponses = <String, String>{
        'master:packages/plugin/pubspec.yaml': 'version: 1.0.0',
        'HEAD:packages/plugin/pubspec.yaml': 'version: 2.0.0',
      };
      final List<String> output = await runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);

      expect(
        output,
        containsAllInOrder(<String>[
          'No version check errors found!',
        ]),
      );
      expect(gitDirCommands.length, equals(3));
      expect(
          gitDirCommands[0].join(' '), equals('diff --name-only master HEAD'));
      expect(gitDirCommands[1].join(' '),
          equals('show master:packages/plugin/pubspec.yaml'));
      expect(gitDirCommands[2].join(' '),
          equals('show HEAD:packages/plugin/pubspec.yaml'));
    });

    test('denies invalid version', () async {
      createFakePlugin('plugin', includeChangeLog: true, includeVersion: true);
      gitDiffResponse = "packages/plugin/pubspec.yaml";
      gitShowResponses = <String, String>{
        'master:packages/plugin/pubspec.yaml': 'version: 0.0.1',
        'HEAD:packages/plugin/pubspec.yaml': 'version: 0.2.0',
      };
      final Future<List<String>> result = runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);

      await expectLater(
        result,
        throwsA(const TypeMatcher<Error>()),
      );
      expect(gitDirCommands.length, equals(3));
      expect(
          gitDirCommands[0].join(' '), equals('diff --name-only master HEAD'));
      expect(gitDirCommands[1].join(' '),
          equals('show master:packages/plugin/pubspec.yaml'));
      expect(gitDirCommands[2].join(' '),
          equals('show HEAD:packages/plugin/pubspec.yaml'));
    });

    test('gracefully handles missing pubspec.yaml', () async {
      createFakePlugin('plugin', includeChangeLog: true, includeVersion: true);
      gitDiffResponse = "packages/plugin/pubspec.yaml";
      mockFileSystem.currentDirectory
          .childDirectory('packages')
          .childDirectory('plugin')
          .childFile('pubspec.yaml')
          .deleteSync();
      final List<String> output = await runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);

      expect(
        output,
        orderedEquals(<String>[
          'Determine diff with base sha: master',
          'No version check errors found!',
        ]),
      );
      expect(gitDirCommands.length, equals(1));
      expect(gitDirCommands.first.join(' '),
          equals('diff --name-only master HEAD'));
    });

    test('allows minor changes to platform interfaces', () async {
      createFakePlugin('plugin_platform_interface',
          includeChangeLog: true, includeVersion: true);
      gitDiffResponse = "packages/plugin_platform_interface/pubspec.yaml";
      gitShowResponses = <String, String>{
        'master:packages/plugin_platform_interface/pubspec.yaml':
            'version: 1.0.0',
        'HEAD:packages/plugin_platform_interface/pubspec.yaml':
            'version: 1.1.0',
      };
      final List<String> output = await runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);
      expect(
        output,
        containsAllInOrder(<String>[
          'No version check errors found!',
        ]),
      );
      expect(gitDirCommands.length, equals(3));
      expect(
          gitDirCommands[0].join(' '), equals('diff --name-only master HEAD'));
      expect(
          gitDirCommands[1].join(' '),
          equals(
              'show master:packages/plugin_platform_interface/pubspec.yaml'));
      expect(gitDirCommands[2].join(' '),
          equals('show HEAD:packages/plugin_platform_interface/pubspec.yaml'));
    });

    test('disallows breaking changes to platform interfaces', () async {
      createFakePlugin('plugin_platform_interface',
          includeChangeLog: true, includeVersion: true);
      gitDiffResponse = "packages/plugin_platform_interface/pubspec.yaml";
      gitShowResponses = <String, String>{
        'master:packages/plugin_platform_interface/pubspec.yaml':
            'version: 1.0.0',
        'HEAD:packages/plugin_platform_interface/pubspec.yaml':
            'version: 2.0.0',
      };
      final Future<List<String>> output = runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);
      await expectLater(
        output,
        throwsA(const TypeMatcher<Error>()),
      );
      expect(gitDirCommands.length, equals(3));
      expect(
          gitDirCommands[0].join(' '), equals('diff --name-only master HEAD'));
      expect(
          gitDirCommands[1].join(' '),
          equals(
              'show master:packages/plugin_platform_interface/pubspec.yaml'));
      expect(gitDirCommands[2].join(' '),
          equals('show HEAD:packages/plugin_platform_interface/pubspec.yaml'));
    });

    test('Allow empty lines in front of the first version in CHANGELOG',
        () async {
      createFakePlugin('plugin', includeChangeLog: true, includeVersion: true);

      final Directory pluginDirectory =
          mockPackagesDir.childDirectory('plugin');

      createFakePubspec(pluginDirectory,
          isFlutter: true, includeVersion: true, version: '1.0.1');
      String changelog = '''
      


## 1.0.1

* Some changes.
''';
      createFakeCHANGELOG(pluginDirectory, changelog);
      final List<String> output = await runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);
      await expect(
        output,
        containsAllInOrder([
          'Checking the first version listed in CHANGELOG.MD matches the version in pubspec.yaml for plugin.',
          'plugin passed version check',
          'No version check errors found!'
        ]),
      );
    });

    test('Throws if versions in changelog and pubspec do not match', () async {
      createFakePlugin('plugin', includeChangeLog: true, includeVersion: true);

      final Directory pluginDirectory =
          mockPackagesDir.childDirectory('plugin');

      createFakePubspec(pluginDirectory,
          isFlutter: true, includeVersion: true, version: '1.0.1');
      String changelog = '''
## 1.0.2

* Some changes.
''';
      createFakeCHANGELOG(pluginDirectory, changelog);
      final Future<List<String>> output = runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);
      await expectLater(
        output,
        throwsA(const TypeMatcher<Error>()),
      );
      try {
        List<String> outputValue = await output;
        await expectLater(
          outputValue,
          containsAllInOrder([
            '''
  versions for plugin in CHANGELOG.md and pubspec.yaml do not match.
  The version in pubspec.yaml is 1.0.1.
  The first version listed in CHANGELOG.md is 1.0.2.
  ''',
          ]),
        );
      } on ToolExit catch (_) {}
    });

    test('Success if CHANGELOG and pubspec versions match', () async {
      createFakePlugin('plugin', includeChangeLog: true, includeVersion: true);

      final Directory pluginDirectory =
          mockPackagesDir.childDirectory('plugin');

      createFakePubspec(pluginDirectory,
          isFlutter: true, includeVersion: true, version: '1.0.1');
      String changelog = '''
## 1.0.1

* Some changes.
''';
      createFakeCHANGELOG(pluginDirectory, changelog);
      final List<String> output = await runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);
      await expect(
        output,
        containsAllInOrder([
          'Checking the first version listed in CHANGELOG.MD matches the version in pubspec.yaml for plugin.',
          'plugin passed version check',
          'No version check errors found!'
        ]),
      );
    });

    test(
        'Fail if pubspec version only matches an older version listed in CHANGELOG',
        () async {
      createFakePlugin('plugin', includeChangeLog: true, includeVersion: true);

      final Directory pluginDirectory =
          mockPackagesDir.childDirectory('plugin');

      createFakePubspec(pluginDirectory,
          isFlutter: true, includeVersion: true, version: '1.0.0');
      String changelog = '''
## 1.0.1

* Some changes.

## 1.0.0

* Some other changes.
''';
      createFakeCHANGELOG(pluginDirectory, changelog);
      Future<List<String>> output = runCapturingPrint(
          runner, <String>['version-check', '--base-sha=master']);
      await expectLater(
        output,
        throwsA(const TypeMatcher<Error>()),
      );
      try {
        List<String> outputValue = await output;
        await expectLater(
          outputValue,
          containsAllInOrder([
            '''
  versions for plugin in CHANGELOG.md and pubspec.yaml do not match.
  The version in pubspec.yaml is 1.0.0.
  The first version listed in CHANGELOG.md is 1.0.1.
  ''',
          ]),
        );
      } on ToolExit catch (_) {}
    });
  });

  group("Pre 1.0", () {
    test("nextVersion allows patch version", () {
      testAllowedVersion("0.12.0", "0.12.0+1",
          nextVersionType: NextVersionType.PATCH);
      testAllowedVersion("0.12.0+4", "0.12.0+5",
          nextVersionType: NextVersionType.PATCH);
    });

    test("nextVersion does not allow jumping patch", () {
      testAllowedVersion("0.12.0", "0.12.0+2", allowed: false);
      testAllowedVersion("0.12.0+2", "0.12.0+4", allowed: false);
    });

    test("nextVersion does not allow going back", () {
      testAllowedVersion("0.12.0", "0.11.0", allowed: false);
      testAllowedVersion("0.12.0+2", "0.12.0+1", allowed: false);
      testAllowedVersion("0.12.0+1", "0.12.0", allowed: false);
    });

    test("nextVersion allows minor version", () {
      testAllowedVersion("0.12.0", "0.12.1",
          nextVersionType: NextVersionType.MINOR);
      testAllowedVersion("0.12.0+4", "0.12.1",
          nextVersionType: NextVersionType.MINOR);
    });

    test("nextVersion does not allow jumping minor", () {
      testAllowedVersion("0.12.0", "0.12.2", allowed: false);
      testAllowedVersion("0.12.0+2", "0.12.3", allowed: false);
    });
  });

  group("Releasing 1.0", () {
    test("nextVersion allows releasing 1.0", () {
      testAllowedVersion("0.12.0", "1.0.0",
          nextVersionType: NextVersionType.BREAKING_MAJOR);
      testAllowedVersion("0.12.0+4", "1.0.0",
          nextVersionType: NextVersionType.BREAKING_MAJOR);
    });

    test("nextVersion does not allow jumping major", () {
      testAllowedVersion("0.12.0", "2.0.0", allowed: false);
      testAllowedVersion("0.12.0+4", "2.0.0", allowed: false);
    });

    test("nextVersion does not allow un-releasing", () {
      testAllowedVersion("1.0.0", "0.12.0+4", allowed: false);
      testAllowedVersion("1.0.0", "0.12.0", allowed: false);
    });
  });

  group("Post 1.0", () {
    test("nextVersion allows patch jumps", () {
      testAllowedVersion("1.0.1", "1.0.2",
          nextVersionType: NextVersionType.PATCH);
      testAllowedVersion("1.0.0", "1.0.1",
          nextVersionType: NextVersionType.PATCH);
    });

    test("nextVersion does not allow build jumps", () {
      testAllowedVersion("1.0.1", "1.0.1+1", allowed: false);
      testAllowedVersion("1.0.0+5", "1.0.0+6", allowed: false);
    });

    test("nextVersion does not allow skipping patches", () {
      testAllowedVersion("1.0.1", "1.0.3", allowed: false);
      testAllowedVersion("1.0.0", "1.0.6", allowed: false);
    });

    test("nextVersion allows minor version jumps", () {
      testAllowedVersion("1.0.1", "1.1.0",
          nextVersionType: NextVersionType.MINOR);
      testAllowedVersion("1.0.0", "1.1.0",
          nextVersionType: NextVersionType.MINOR);
    });

    test("nextVersion does not allow skipping minor versions", () {
      testAllowedVersion("1.0.1", "1.2.0", allowed: false);
      testAllowedVersion("1.1.0", "1.3.0", allowed: false);
    });

    test("nextVersion allows breaking changes", () {
      testAllowedVersion("1.0.1", "2.0.0",
          nextVersionType: NextVersionType.BREAKING_MAJOR);
      testAllowedVersion("1.0.0", "2.0.0",
          nextVersionType: NextVersionType.BREAKING_MAJOR);
    });

    test("nextVersion allows null safety pre prelease", () {
      testAllowedVersion("1.0.1", "2.0.0-nullsafety",
          nextVersionType: NextVersionType.MAJOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("1.0.0", "2.0.0-nullsafety",
          nextVersionType: NextVersionType.MAJOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("1.0.0-nullsafety", "1.0.0-nullsafety.1",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("1.0.0-nullsafety.1", "1.0.0-nullsafety.2",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("0.1.0", "0.2.0-nullsafety",
          nextVersionType: NextVersionType.MAJOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("0.1.0-nullsafety", "0.1.0-nullsafety.1",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("0.1.0-nullsafety.1", "0.1.0-nullsafety.2",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("1.0.0", "1.1.0-nullsafety",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("1.1.0-nullsafety", "1.1.0-nullsafety.1",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("0.1.0", "0.1.1-nullsafety",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
      testAllowedVersion("0.1.1-nullsafety", "0.1.1-nullsafety.1",
          nextVersionType: NextVersionType.MINOR_NULLSAFETY_PRE_RELEASE);
    });

    test("nextVersion does not allow skipping major versions", () {
      testAllowedVersion("1.0.1", "3.0.0", allowed: false);
      testAllowedVersion("1.1.0", "2.3.0", allowed: false);
    });
  });
}
