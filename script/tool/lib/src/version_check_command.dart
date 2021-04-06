// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:file/file.dart';
import 'package:git/git.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'common.dart';

const String _kBaseSha = 'base-sha';

/// Categories of version change types.
enum NextVersionType {
  /// A breaking change.
  BREAKING_MAJOR,

  /// A minor change (e.g., added feature).
  MINOR,

  /// A bugfix change.
  PATCH,

  /// The release of an existing prerelease version.
  RELEASE,
}

/// Returns the set of allowed next versions, with their change type, for
/// [masterVersion].
///
/// [headVerison] is used to check whether this is a pre-1.0 version bump, as
/// those have different semver rules.
@visibleForTesting
Map<Version, NextVersionType> getAllowedNextVersions(
    Version masterVersion, Version headVersion) {
  final Map<Version, NextVersionType> allowedNextVersions =
      <Version, NextVersionType>{
    masterVersion.nextMajor: NextVersionType.BREAKING_MAJOR,
    masterVersion.nextMinor: NextVersionType.MINOR,
    masterVersion.nextPatch: NextVersionType.PATCH,
  };

  if (masterVersion.major < 1 && headVersion.major < 1) {
    int nextBuildNumber = -1;
    if (masterVersion.build.isEmpty) {
      nextBuildNumber = 1;
    } else {
      final int currentBuildNumber = masterVersion.build.first as int;
      nextBuildNumber = currentBuildNumber + 1;
    }
    final Version preReleaseVersion = Version(
      masterVersion.major,
      masterVersion.minor,
      masterVersion.patch,
      build: nextBuildNumber.toString(),
    );
    allowedNextVersions.clear();
    allowedNextVersions[masterVersion.nextMajor] = NextVersionType.RELEASE;
    allowedNextVersions[masterVersion.nextMinor] =
        NextVersionType.BREAKING_MAJOR;
    allowedNextVersions[masterVersion.nextPatch] = NextVersionType.MINOR;
    allowedNextVersions[preReleaseVersion] = NextVersionType.PATCH;
  }
  return allowedNextVersions;
}

/// A command to validate version changes to packages.
class VersionCheckCommand extends PluginCommand {
  /// Creates an instance of the version check command.
  VersionCheckCommand(
    Directory packagesDir,
    FileSystem fileSystem, {
    ProcessRunner processRunner = const ProcessRunner(),
    GitDir gitDir,
  }) : super(packagesDir, fileSystem,
            processRunner: processRunner, gitDir: gitDir);

  @override
  final String name = 'version-check';

  @override
  final String description =
      'Checks if the versions of the plugins have been incremented per pub specification.\n'
      'Also checks if the latest version in CHANGELOG matches the version in pubspec.\n\n'
      'This command requires "pub" and "flutter" to be in your path.';

  @override
  Future<void> run() async {
    final GitVersionFinder gitVersionFinder = await retrieveVersionFinder();

    final List<String> changedPubspecs =
        await gitVersionFinder.getChangedPubSpecs();

    final String baseSha = argResults[_kBaseSha] as String;
    for (final String pubspecPath in changedPubspecs) {
      try {
        final File pubspecFile = fileSystem.file(pubspecPath);
        if (!pubspecFile.existsSync()) {
          continue;
        }
        final Pubspec pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
        if (pubspec.publishTo == 'none') {
          continue;
        }

        final Version masterVersion =
            await gitVersionFinder.getPackageVersion(pubspecPath, baseSha);
        final Version headVersion =
            await gitVersionFinder.getPackageVersion(pubspecPath, 'HEAD');
        if (headVersion == null) {
          continue; // Example apps don't have versions
        }

        final Map<Version, NextVersionType> allowedNextVersions =
            getAllowedNextVersions(masterVersion, headVersion);

        if (!allowedNextVersions.containsKey(headVersion)) {
          final String error = '$pubspecPath incorrectly updated version.\n'
              'HEAD: $headVersion, master: $masterVersion.\n'
              'Allowed versions: $allowedNextVersions';
          printErrorAndExit(errorMessage: error);
        }

        final bool isPlatformInterface =
            pubspec.name.endsWith('_platform_interface');
        if (isPlatformInterface &&
            allowedNextVersions[headVersion] ==
                NextVersionType.BREAKING_MAJOR) {
          final String error = '$pubspecPath breaking change detected.\n'
              'Breaking changes to platform interfaces are strongly discouraged.\n';
          printErrorAndExit(errorMessage: error);
        }
      } on io.ProcessException {
        print('Unable to find pubspec in master for $pubspecPath.'
            ' Safe to ignore if the project is new.');
      }
    }

    await for (final Directory plugin in getPlugins()) {
      await _checkVersionsMatch(plugin);
    }

    print('No version check errors found!');
  }

  Future<void> _checkVersionsMatch(Directory plugin) async {
    // get version from pubspec
    final String packageName = plugin.basename;
    print('-----------------------------------------');
    print(
        'Checking the first version listed in CHANGELOG.MD matches the version in pubspec.yaml for $packageName.');

    final Pubspec pubspec = _tryParsePubspec(plugin);
    if (pubspec == null) {
      const String error = 'Cannot parse version from pubspec.yaml';
      printErrorAndExit(errorMessage: error);
    }
    final Version fromPubspec = pubspec.version;

    // get first version from CHANGELOG
    final File changelog = plugin.childFile('CHANGELOG.md');
    final List<String> lines = changelog.readAsLinesSync();
    String firstLineWithText;
    final Iterator<String> iterator = lines.iterator;
    while (iterator.moveNext()) {
      if (iterator.current.trim().isNotEmpty) {
        firstLineWithText = iterator.current;
        break;
      }
    }
    // Remove all leading mark down syntax from the version line.
    final String versionString = firstLineWithText.split(' ').last;
    final Version fromChangeLog = Version.parse(versionString);
    if (fromChangeLog == null) {
      final String error =
          'Cannot find version on the first line of ${plugin.path}/CHANGELOG.md';
      printErrorAndExit(errorMessage: error);
    }

    if (fromPubspec != fromChangeLog) {
      final String error = '''
versions for $packageName in CHANGELOG.md and pubspec.yaml do not match.
The version in pubspec.yaml is $fromPubspec.
The first version listed in CHANGELOG.md is $fromChangeLog.
''';
      printErrorAndExit(errorMessage: error);
    }
    print('$packageName passed version check');
  }

  Pubspec _tryParsePubspec(Directory package) {
    final File pubspecFile = package.childFile('pubspec.yaml');

    try {
      final Pubspec pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
      if (pubspec == null) {
        final String error =
            'Failed to parse `pubspec.yaml` at ${pubspecFile.path}';
        printErrorAndExit(errorMessage: error);
      }
      return pubspec;
    } on Exception catch (exception) {
      final String error =
          'Failed to parse `pubspec.yaml` at ${pubspecFile.path}: $exception}';
      printErrorAndExit(errorMessage: error);
    }
    return null;
  }
}
