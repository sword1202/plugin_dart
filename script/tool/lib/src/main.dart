// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

import 'analyze_command.dart';
import 'build_examples_command.dart';
import 'common/core.dart';
import 'create_all_plugins_app_command.dart';
import 'custom_test_command.dart';
import 'drive_examples_command.dart';
import 'federation_safety_check_command.dart';
import 'firebase_test_lab_command.dart';
import 'format_command.dart';
import 'license_check_command.dart';
import 'lint_android_command.dart';
import 'lint_podspecs_command.dart';
import 'list_command.dart';
import 'make_deps_path_based_command.dart';
import 'native_test_command.dart';
import 'publish_check_command.dart';
import 'publish_plugin_command.dart';
import 'pubspec_check_command.dart';
import 'readme_check_command.dart';
import 'test_command.dart';
import 'update_excerpts_command.dart';
import 'version_check_command.dart';
import 'xcode_analyze_command.dart';

void main(List<String> args) {
  const FileSystem fileSystem = LocalFileSystem();

  Directory packagesDir =
      fileSystem.currentDirectory.childDirectory('packages');

  if (!packagesDir.existsSync()) {
    if (fileSystem.currentDirectory.basename == 'packages') {
      packagesDir = fileSystem.currentDirectory;
    } else {
      print('Error: Cannot find a "packages" sub-directory');
      io.exit(1);
    }
  }

  final CommandRunner<void> commandRunner = CommandRunner<void>(
      'pub global run flutter_plugin_tools',
      'Productivity utils for hosting multiple plugins within one repository.')
    ..addCommand(AnalyzeCommand(packagesDir))
    ..addCommand(BuildExamplesCommand(packagesDir))
    ..addCommand(CreateAllPluginsAppCommand(packagesDir))
    ..addCommand(CustomTestCommand(packagesDir))
    ..addCommand(DriveExamplesCommand(packagesDir))
    ..addCommand(FederationSafetyCheckCommand(packagesDir))
    ..addCommand(FirebaseTestLabCommand(packagesDir))
    ..addCommand(FormatCommand(packagesDir))
    ..addCommand(LicenseCheckCommand(packagesDir))
    ..addCommand(LintAndroidCommand(packagesDir))
    ..addCommand(LintPodspecsCommand(packagesDir))
    ..addCommand(ListCommand(packagesDir))
    ..addCommand(NativeTestCommand(packagesDir))
    ..addCommand(MakeDepsPathBasedCommand(packagesDir))
    ..addCommand(PublishCheckCommand(packagesDir))
    ..addCommand(PublishPluginCommand(packagesDir))
    ..addCommand(PubspecCheckCommand(packagesDir))
    ..addCommand(ReadmeCheckCommand(packagesDir))
    ..addCommand(TestCommand(packagesDir))
    ..addCommand(UpdateExcerptsCommand(packagesDir))
    ..addCommand(VersionCheckCommand(packagesDir))
    ..addCommand(XcodeAnalyzeCommand(packagesDir));

  commandRunner.run(args).catchError((Object e) {
    final ToolExit toolExit = e as ToolExit;
    int exitCode = toolExit.exitCode;
    // This should never happen; this check is here to guarantee that a ToolExit
    // never accidentally has code 0 thus causing CI to pass.
    if (exitCode == 0) {
      assert(false);
      exitCode = 255;
    }
    io.exit(exitCode);
  }, test: (Object e) => e is ToolExit);
}
