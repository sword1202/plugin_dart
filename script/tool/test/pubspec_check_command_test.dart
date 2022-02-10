// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_plugin_tools/src/common/core.dart';
import 'package:flutter_plugin_tools/src/pubspec_check_command.dart';
import 'package:test/test.dart';

import 'mocks.dart';
import 'util.dart';

/// Returns the top section of a pubspec.yaml for a package named [name],
/// for either a flutter/packages or flutter/plugins package depending on
/// the values of [isPlugin].
///
/// By default it will create a header that includes all of the expected
/// values, elements can be changed via arguments to create incorrect
/// entries.
///
/// If [includeRepository] is true, by default the path in the link will
/// be "packages/[name]"; a different "packages"-relative path can be
/// provided with [repositoryPackagesDirRelativePath].
String _headerSection(
  String name, {
  bool isPlugin = false,
  bool includeRepository = true,
  String? repositoryPackagesDirRelativePath,
  bool includeHomepage = false,
  bool includeIssueTracker = true,
  bool publishable = true,
  String? description,
}) {
  final String repositoryPath = repositoryPackagesDirRelativePath ?? name;
  final List<String> repoLinkPathComponents = <String>[
    'flutter',
    if (isPlugin) 'plugins' else 'packages',
    'tree',
    'main',
    'packages',
    repositoryPath,
  ];
  final String repoLink =
      'https://github.com/' + repoLinkPathComponents.join('/');
  final String issueTrackerLink = 'https://github.com/flutter/flutter/issues?'
      'q=is%3Aissue+is%3Aopen+label%3A%22p%3A+$name%22';
  description ??= 'A test package for validating that the pubspec.yaml '
      'follows repo best practices.';
  return '''
name: $name
description: $description
${includeRepository ? 'repository: $repoLink' : ''}
${includeHomepage ? 'homepage: $repoLink' : ''}
${includeIssueTracker ? 'issue_tracker: $issueTrackerLink' : ''}
version: 1.0.0
${publishable ? '' : 'publish_to: \'none\''}
''';
}

String _environmentSection() {
  return '''
environment:
  sdk: ">=2.12.0 <3.0.0"
  flutter: ">=2.0.0"
''';
}

String _flutterSection({
  bool isPlugin = false,
  String? implementedPackage,
  Map<String, Map<String, String>> pluginPlatformDetails =
      const <String, Map<String, String>>{},
}) {
  String pluginEntry = '''
  plugin:
${implementedPackage == null ? '' : '    implements: $implementedPackage'}
    platforms:
''';

  for (final MapEntry<String, Map<String, String>> platform
      in pluginPlatformDetails.entries) {
    pluginEntry += '''
      ${platform.key}:
''';
    for (final MapEntry<String, String> detail in platform.value.entries) {
      pluginEntry += '''
        ${detail.key}: ${detail.value}
''';
    }
  }

  return '''
flutter:
${isPlugin ? pluginEntry : ''}
''';
}

String _dependenciesSection() {
  return '''
dependencies:
  flutter:
    sdk: flutter
''';
}

String _devDependenciesSection() {
  return '''
dev_dependencies:
  flutter_test:
    sdk: flutter
''';
}

String _falseSecretsSection() {
  return '''
false_secrets:
  - /lib/main.dart
''';
}

void main() {
  group('test pubspec_check_command', () {
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
      final PubspecCheckCommand command = PubspecCheckCommand(
        packagesDir,
        processRunner: processRunner,
        platform: mockPlatform,
      );

      runner = CommandRunner<void>(
          'pubspec_check_command', 'Test for pubspec_check_command');
      runner.addCommand(command);
    });

    test('passes for a plugin following conventions', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
${_falseSecretsSection()}
''');

      final List<String> output = await runCapturingPrint(runner, <String>[
        'pubspec-check',
      ]);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin...'),
          contains('Running for plugin/example...'),
          contains('No issues found!'),
        ]),
      );
    });

    test('passes for a Flutter package following conventions', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin')}
${_environmentSection()}
${_dependenciesSection()}
${_devDependenciesSection()}
${_flutterSection()}
${_falseSecretsSection()}
''');

      final List<String> output = await runCapturingPrint(runner, <String>[
        'pubspec-check',
      ]);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin...'),
          contains('Running for plugin/example...'),
          contains('No issues found!'),
        ]),
      );
    });

    test('passes for a minimal package following conventions', () async {
      final Directory packageDirectory = packagesDir.childDirectory('package');
      packageDirectory.createSync(recursive: true);

      packageDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('package')}
${_environmentSection()}
${_dependenciesSection()}
''');

      final List<String> output = await runCapturingPrint(runner, <String>[
        'pubspec-check',
      ]);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for package...'),
          contains('No issues found!'),
        ]),
      );
    });

    test('fails when homepage is included', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, includeHomepage: true)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Found a "homepage" entry; only "repository" should be used.'),
        ]),
      );
    });

    test('fails when repository is missing', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, includeRepository: false)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Missing "repository"'),
        ]),
      );
    });

    test('fails when homepage is given instead of repository', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, includeHomepage: true, includeRepository: false)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Found a "homepage" entry; only "repository" should be used.'),
        ]),
      );
    });

    test('fails when repository is incorrect', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, repositoryPackagesDirRelativePath: 'different_plugin')}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('The "repository" link should end with the package path.'),
        ]),
      );
    });

    test('fails when issue tracker is missing', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, includeIssueTracker: false)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('A package should have an "issue_tracker" link'),
        ]),
      );
    });

    test('fails when description is too short', () async {
      final Directory pluginDirectory =
          createFakePlugin('a_plugin', packagesDir.childDirectory('a_plugin'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, description: 'Too short')}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('"description" is too short. pub.dev recommends package '
              'descriptions of 60-180 characters.'),
        ]),
      );
    });

    test(
        'allows short descriptions for non-app-facing parts of federated plugins',
        () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, description: 'Too short')}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('"description" is too short. pub.dev recommends package '
              'descriptions of 60-180 characters.'),
        ]),
      );
    });

    test('fails when description is too long', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      const String description = 'This description is too long. It just goes '
          'on and on and on and on and on. pub.dev will down-score it because '
          'there is just too much here. Someone shoul really cut this down to just '
          'the core description so that search results are more useful and the '
          'package does not lose pub points.';
      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true, description: description)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('"description" is too long. pub.dev recommends package '
              'descriptions of 60-180 characters.'),
        ]),
      );
    });

    test('fails when environment section is out of order', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true)}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
${_environmentSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Major sections should follow standard repository ordering:'),
        ]),
      );
    });

    test('fails when flutter section is out of order', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true)}
${_flutterSection(isPlugin: true)}
${_environmentSection()}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Major sections should follow standard repository ordering:'),
        ]),
      );
    });

    test('fails when dependencies section is out of order', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_devDependenciesSection()}
${_dependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Major sections should follow standard repository ordering:'),
        ]),
      );
    });

    test('fails when dev_dependencies section is out of order', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true)}
${_environmentSection()}
${_devDependenciesSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Major sections should follow standard repository ordering:'),
        ]),
      );
    });

    test('fails when false_secrets section is out of order', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin', isPlugin: true)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_falseSecretsSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Major sections should follow standard repository ordering:'),
        ]),
      );
    });

    test('fails when an implemenation package is missing "implements"',
        () async {
      final Directory pluginDirectory = createFakePlugin(
          'plugin_a_foo', packagesDir.childDirectory('plugin_a'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin_a_foo', isPlugin: true)}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Missing "implements: plugin_a" in "plugin" section.'),
        ]),
      );
    });

    test('fails when an implemenation package has the wrong "implements"',
        () async {
      final Directory pluginDirectory = createFakePlugin(
          'plugin_a_foo', packagesDir.childDirectory('plugin_a'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin_a_foo', isPlugin: true)}
${_environmentSection()}
${_flutterSection(isPlugin: true, implementedPackage: 'plugin_a_foo')}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Expecetd "implements: plugin_a"; '
              'found "implements: plugin_a_foo".'),
        ]),
      );
    });

    test('passes for a correct implemenation package', () async {
      final Directory pluginDirectory = createFakePlugin(
          'plugin_a_foo', packagesDir.childDirectory('plugin_a'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection(
        'plugin_a_foo',
        isPlugin: true,
        repositoryPackagesDirRelativePath: 'plugin_a/plugin_a_foo',
      )}
${_environmentSection()}
${_flutterSection(isPlugin: true, implementedPackage: 'plugin_a')}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      final List<String> output =
          await runCapturingPrint(runner, <String>['pubspec-check']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin_a_foo...'),
          contains('No issues found!'),
        ]),
      );
    });

    test('fails when a "default_package" looks incorrect', () async {
      final Directory pluginDirectory =
          createFakePlugin('plugin_a', packagesDir.childDirectory('plugin_a'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection(
        'plugin_a',
        isPlugin: true,
        repositoryPackagesDirRelativePath: 'plugin_a/plugin_a',
      )}
${_environmentSection()}
${_flutterSection(
        isPlugin: true,
        pluginPlatformDetails: <String, Map<String, String>>{
          'android': <String, String>{'default_package': 'plugin_b_android'}
        },
      )}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              '"plugin_b_android" is not an expected implementation name for "plugin_a"'),
        ]),
      );
    });

    test(
        'fails when a "default_package" does not have a corresponding dependency',
        () async {
      final Directory pluginDirectory =
          createFakePlugin('plugin_a', packagesDir.childDirectory('plugin_a'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection(
        'plugin_a',
        isPlugin: true,
        repositoryPackagesDirRelativePath: 'plugin_a/plugin_a',
      )}
${_environmentSection()}
${_flutterSection(
        isPlugin: true,
        pluginPlatformDetails: <String, Map<String, String>>{
          'android': <String, String>{'default_package': 'plugin_a_android'}
        },
      )}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('The following default_packages are missing corresponding '
              'dependencies:\n  plugin_a_android'),
        ]),
      );
    });

    test('passes for an app-facing package without "implements"', () async {
      final Directory pluginDirectory =
          createFakePlugin('plugin_a', packagesDir.childDirectory('plugin_a'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection(
        'plugin_a',
        isPlugin: true,
        repositoryPackagesDirRelativePath: 'plugin_a/plugin_a',
      )}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      final List<String> output =
          await runCapturingPrint(runner, <String>['pubspec-check']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin_a/plugin_a...'),
          contains('No issues found!'),
        ]),
      );
    });

    test('passes for a platform interface package without "implements"',
        () async {
      final Directory pluginDirectory = createFakePlugin(
          'plugin_a_platform_interface',
          packagesDir.childDirectory('plugin_a'));

      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection(
        'plugin_a_platform_interface',
        isPlugin: true,
        repositoryPackagesDirRelativePath:
            'plugin_a/plugin_a_platform_interface',
      )}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      final List<String> output =
          await runCapturingPrint(runner, <String>['pubspec-check']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin_a_platform_interface...'),
          contains('No issues found!'),
        ]),
      );
    });

    test('validates some properties even for unpublished packages', () async {
      final Directory pluginDirectory = createFakePlugin(
          'plugin_a_foo', packagesDir.childDirectory('plugin_a'));

      // Environment section is in the wrong location.
      // Missing 'implements'.
      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('plugin_a_foo', isPlugin: true, publishable: false)}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
${_environmentSection()}
''');

      Error? commandError;
      final List<String> output = await runCapturingPrint(
          runner, <String>['pubspec-check'], errorHandler: (Error e) {
        commandError = e;
      });

      expect(commandError, isA<ToolExit>());
      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains(
              'Major sections should follow standard repository ordering:'),
          contains('Missing "implements: plugin_a" in "plugin" section.'),
        ]),
      );
    });

    test('ignores some checks for unpublished packages', () async {
      final Directory pluginDirectory = createFakePlugin('plugin', packagesDir);

      // Missing metadata that is only useful for published packages, such as
      // repository and issue tracker.
      pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection(
        'plugin',
        isPlugin: true,
        publishable: false,
        includeRepository: false,
        includeIssueTracker: false,
      )}
${_environmentSection()}
${_flutterSection(isPlugin: true)}
${_dependenciesSection()}
${_devDependenciesSection()}
''');

      final List<String> output =
          await runCapturingPrint(runner, <String>['pubspec-check']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for plugin...'),
          contains('No issues found!'),
        ]),
      );
    });
  });

  group('test pubspec_check_command on Windows', () {
    late CommandRunner<void> runner;
    late RecordingProcessRunner processRunner;
    late FileSystem fileSystem;
    late MockPlatform mockPlatform;
    late Directory packagesDir;

    setUp(() {
      fileSystem = MemoryFileSystem(style: FileSystemStyle.windows);
      mockPlatform = MockPlatform(isWindows: true);
      packagesDir = fileSystem.currentDirectory.childDirectory('packages');
      createPackagesDirectory(parentDir: packagesDir.parent);
      processRunner = RecordingProcessRunner();
      final PubspecCheckCommand command = PubspecCheckCommand(
        packagesDir,
        processRunner: processRunner,
        platform: mockPlatform,
      );

      runner = CommandRunner<void>(
          'pubspec_check_command', 'Test for pubspec_check_command');
      runner.addCommand(command);
    });

    test('repository check works', () async {
      final Directory packageDirectory =
          createFakePackage('package', packagesDir);

      packageDirectory.childFile('pubspec.yaml').writeAsStringSync('''
${_headerSection('package')}
${_environmentSection()}
${_dependenciesSection()}
''');

      final List<String> output =
          await runCapturingPrint(runner, <String>['pubspec-check']);

      expect(
        output,
        containsAllInOrder(<Matcher>[
          contains('Running for package...'),
          contains('No issues found!'),
        ]),
      );
    });
  });
}
