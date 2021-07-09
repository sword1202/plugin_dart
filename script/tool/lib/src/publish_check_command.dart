// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:platform/platform.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'common/core.dart';
import 'common/package_looping_command.dart';
import 'common/process_runner.dart';
import 'common/pub_version_finder.dart';

/// A command to check that packages are publishable via 'dart publish'.
class PublishCheckCommand extends PackageLoopingCommand {
  /// Creates an instance of the publish command.
  PublishCheckCommand(
    Directory packagesDir, {
    ProcessRunner processRunner = const ProcessRunner(),
    Platform platform = const LocalPlatform(),
    http.Client? httpClient,
  })  : _pubVersionFinder =
            PubVersionFinder(httpClient: httpClient ?? http.Client()),
        super(packagesDir, processRunner: processRunner, platform: platform) {
    argParser.addFlag(
      _allowPrereleaseFlag,
      help: 'Allows the pre-release SDK warning to pass.\n'
          'When enabled, a pub warning, which asks to publish the package as a pre-release version when '
          'the SDK constraint is a pre-release version, is ignored.',
      defaultsTo: false,
    );
    argParser.addFlag(_machineFlag,
        help: 'Switch outputs to a machine readable JSON. \n'
            'The JSON contains a "status" field indicating the final status of the command, the possible values are:\n'
            '    $_statusNeedsPublish: There is at least one package need to be published. They also passed all publish checks.\n'
            '    $_statusMessageNoPublish: There are no packages needs to be published. Either no pubspec change detected or all versions have already been published.\n'
            '    $_statusMessageError: Some error has occurred.',
        defaultsTo: false,
        negatable: true);
  }

  static const String _allowPrereleaseFlag = 'allow-pre-release';
  static const String _machineFlag = 'machine';
  static const String _statusNeedsPublish = 'needs-publish';
  static const String _statusMessageNoPublish = 'no-publish';
  static const String _statusMessageError = 'error';
  static const String _statusKey = 'status';
  static const String _humanMessageKey = 'humanMessage';

  @override
  final String name = 'publish-check';

  @override
  final String description =
      'Checks to make sure that a plugin *could* be published.';

  final PubVersionFinder _pubVersionFinder;

  /// The overall result of the run for machine-readable output. This is the
  /// highest value that occurs during the run.
  _PublishCheckResult _overallResult = _PublishCheckResult.nothingToPublish;

  @override
  bool get captureOutput => getBoolArg(_machineFlag);

  @override
  Future<void> initializeRun() async {
    _overallResult = _PublishCheckResult.nothingToPublish;
  }

  @override
  Future<PackageResult> runForPackage(Directory package) async {
    final _PublishCheckResult? result = await _passesPublishCheck(package);
    if (result == null) {
      return PackageResult.skip('Package is marked as unpublishable.');
    }
    if (result.index > _overallResult.index) {
      _overallResult = result;
    }
    return result == _PublishCheckResult.error
        ? PackageResult.fail()
        : PackageResult.success();
  }

  @override
  Future<void> completeRun() async {
    _pubVersionFinder.httpClient.close();
  }

  @override
  Future<void> handleCapturedOutput(List<String> output) async {
    final Map<String, dynamic> machineOutput = <String, dynamic>{
      _statusKey: _statusStringForResult(_overallResult),
      _humanMessageKey: output,
    };

    print(const JsonEncoder.withIndent('  ').convert(machineOutput));
  }

  String _statusStringForResult(_PublishCheckResult result) {
    switch (result) {
      case _PublishCheckResult.nothingToPublish:
        return _statusMessageNoPublish;
      case _PublishCheckResult.needsPublishing:
        return _statusNeedsPublish;
      case _PublishCheckResult.error:
        return _statusMessageError;
    }
  }

  Pubspec? _tryParsePubspec(Directory package) {
    final File pubspecFile = package.childFile('pubspec.yaml');

    try {
      return Pubspec.parse(pubspecFile.readAsStringSync());
    } on Exception catch (exception) {
      print(
        'Failed to parse `pubspec.yaml` at ${pubspecFile.path}: $exception}',
      );
      return null;
    }
  }

  Future<bool> _hasValidPublishCheckRun(Directory package) async {
    print('Running pub publish --dry-run:');
    final io.Process process = await processRunner.start(
      flutterCommand,
      <String>['pub', 'publish', '--', '--dry-run'],
      workingDirectory: package,
    );

    final StringBuffer outputBuffer = StringBuffer();

    final Completer<void> stdOutCompleter = Completer<void>();
    process.stdout.listen(
      (List<int> event) {
        final String output = String.fromCharCodes(event);
        if (output.isNotEmpty) {
          print(output);
          outputBuffer.write(output);
        }
      },
      onDone: () => stdOutCompleter.complete(),
    );

    final Completer<void> stdInCompleter = Completer<void>();
    process.stderr.listen(
      (List<int> event) {
        final String output = String.fromCharCodes(event);
        if (output.isNotEmpty) {
          // The final result is always printed on stderr, whether success or
          // failure.
          final bool isError = !output.contains('has 0 warnings');
          _printImportantStatusMessage(output, isError: isError);
          outputBuffer.write(output);
        }
      },
      onDone: () => stdInCompleter.complete(),
    );

    if (await process.exitCode == 0) {
      return true;
    }

    if (!getBoolArg(_allowPrereleaseFlag)) {
      return false;
    }

    await stdOutCompleter.future;
    await stdInCompleter.future;

    final String output = outputBuffer.toString();
    return output.contains('Package has 1 warning') &&
        output.contains(
            'Packages with an SDK constraint on a pre-release of the Dart SDK should themselves be published as a pre-release version.');
  }

  /// Returns the result of the publish check, or null if the package is marked
  /// as unpublishable.
  Future<_PublishCheckResult?> _passesPublishCheck(Directory package) async {
    final String packageName = package.basename;
    final Pubspec? pubspec = _tryParsePubspec(package);
    if (pubspec == null) {
      print('no pubspec');
      return _PublishCheckResult.error;
    } else if (pubspec.publishTo == 'none') {
      return null;
    }

    final Version? version = pubspec.version;
    final _PublishCheckResult alreadyPublishedResult =
        await _checkPublishingStatus(
            packageName: packageName, version: version);
    if (alreadyPublishedResult == _PublishCheckResult.nothingToPublish) {
      print(
          'Package $packageName version: $version has already be published on pub.');
      return alreadyPublishedResult;
    } else if (alreadyPublishedResult == _PublishCheckResult.error) {
      print('Check pub version failed $packageName');
      return _PublishCheckResult.error;
    }

    if (await _hasValidPublishCheckRun(package)) {
      print('Package $packageName is able to be published.');
      return _PublishCheckResult.needsPublishing;
    } else {
      print('Unable to publish $packageName');
      return _PublishCheckResult.error;
    }
  }

  // Check if `packageName` already has `version` published on pub.
  Future<_PublishCheckResult> _checkPublishingStatus(
      {required String packageName, required Version? version}) async {
    final PubVersionFinderResponse pubVersionFinderResponse =
        await _pubVersionFinder.getPackageVersion(package: packageName);
    switch (pubVersionFinderResponse.result) {
      case PubVersionFinderResult.success:
        return pubVersionFinderResponse.versions.contains(version)
            ? _PublishCheckResult.nothingToPublish
            : _PublishCheckResult.needsPublishing;
      case PubVersionFinderResult.fail:
        print('''
Error fetching version on pub for $packageName.
HTTP Status ${pubVersionFinderResponse.httpResponse.statusCode}
HTTP response: ${pubVersionFinderResponse.httpResponse.body}
''');
        return _PublishCheckResult.error;
      case PubVersionFinderResult.noPackageFound:
        return _PublishCheckResult.needsPublishing;
    }
  }

  void _printImportantStatusMessage(String message, {required bool isError}) {
    final String statusMessage = '${isError ? 'ERROR' : 'SUCCESS'}: $message';
    if (getBoolArg(_machineFlag)) {
      print(statusMessage);
    } else {
      if (isError) {
        printError(statusMessage);
      } else {
        printSuccess(statusMessage);
      }
    }
  }
}

/// Possible outcomes of of a publishing check.
enum _PublishCheckResult {
  nothingToPublish,
  needsPublishing,
  error,
}
