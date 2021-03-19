// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:git/git.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'common.dart';

/// Wraps pub publish with a few niceties used by the flutter/plugin team.
///
/// 1. Checks for any modified files in git and refuses to publish if there's an
///    issue.
/// 2. Tags the release with the format <package-name>-v<package-version>.
/// 3. Pushes the release to a remote.
///
/// Both 2 and 3 are optional, see `plugin_tools help publish-plugin` for full
/// usage information.
///
/// [processRunner], [print], and [stdin] can be overriden for easier testing.
class PublishPluginCommand extends PluginCommand {
  PublishPluginCommand(
    Directory packagesDir,
    FileSystem fileSystem, {
    ProcessRunner processRunner = const ProcessRunner(),
    Print print = print,
    Stdin stdinput,
  })  : _print = print,
        _stdin = stdinput ?? stdin,
        super(packagesDir, fileSystem, processRunner: processRunner) {
    argParser.addOption(
      _packageOption,
      help: 'The package to publish.'
          'If the package directory name is different than its pubspec.yaml name, then this should specify the directory.',
    );
    argParser.addMultiOption(_pubFlagsOption,
        help:
            'A list of options that will be forwarded on to pub. Separate multiple flags with commas.');
    argParser.addFlag(
      _tagReleaseOption,
      help: 'Whether or not to tag the release.',
      defaultsTo: true,
      negatable: true,
    );
    argParser.addFlag(
      _pushTagsOption,
      help:
          'Whether or not tags should be pushed to a remote after creation. Ignored if tag-release is false.',
      defaultsTo: true,
      negatable: true,
    );
    argParser.addOption(
      _remoteOption,
      help:
          'The name of the remote to push the tags to. Ignored if push-tags or tag-release is false.',
      // Flutter convention is to use "upstream" for the single source of truth, and "origin" for personal forks.
      defaultsTo: 'upstream',
    );
  }

  static const String _packageOption = 'package';
  static const String _tagReleaseOption = 'tag-release';
  static const String _pushTagsOption = 'push-tags';
  static const String _pubFlagsOption = 'pub-publish-flags';
  static const String _remoteOption = 'remote';

  // Version tags should follow <package-name>-v<semantic-version>. For example,
  // `flutter_plugin_tools-v0.0.24`.
  static const String _tagFormat = '%PACKAGE%-v%VERSION%';

  @override
  final String name = 'publish-plugin';

  @override
  final String description =
      'Attempts to publish the given plugin and tag its release on GitHub.';

  final Print _print;
  final Stdin _stdin;
  // The directory of the actual package that we are publishing.
  Directory _packageDir;
  StreamSubscription<String> _stdinSubscription;

  @override
  Future<Null> run() async {
    checkSharding();
    _print('Checking local repo...');
    _packageDir = _checkPackageDir();
    await _checkGitStatus();
    final bool shouldPushTag = argResults[_pushTagsOption];
    final String remote = argResults[_remoteOption];
    String remoteUrl;
    if (shouldPushTag) {
      remoteUrl = await _verifyRemote(remote);
    }
    _print('Local repo is ready!');

    await _publish();
    _print('Package published!');
    if (!argResults[_tagReleaseOption]) {
      return await _finishSuccesfully();
    }

    _print('Tagging release...');
    final String tag = _getTag();
    await processRunner.runAndExitOnError('git', <String>['tag', tag],
        workingDir: _packageDir);
    if (!shouldPushTag) {
      return await _finishSuccesfully();
    }

    _print('Pushing tag to $remote...');
    await _pushTagToRemote(remote: remote, tag: tag, remoteUrl: remoteUrl);
    await _finishSuccesfully();
  }

  Future<void> _finishSuccesfully() async {
    await _stdinSubscription.cancel();
    _print('Done!');
  }

  Directory _checkPackageDir() {
    final String package = argResults[_packageOption];
    if (package == null) {
      _print(
          'Must specify a package to publish. See `plugin_tools help publish-plugin`.');
      throw ToolExit(1);
    }
    final Directory _packageDir = packagesDir.childDirectory(package);
    if (!_packageDir.existsSync()) {
      _print('${_packageDir.absolute.path} does not exist.');
      throw ToolExit(1);
    }
    return _packageDir;
  }

  Future<void> _checkGitStatus() async {
    if (!await GitDir.isGitDir(packagesDir.path)) {
      _print('$packagesDir is not a valid Git repository.');
      throw ToolExit(1);
    }

    final ProcessResult statusResult = await processRunner.runAndExitOnError(
        'git',
        <String>[
          'status',
          '--porcelain',
          '--ignored',
          _packageDir.absolute.path
        ],
        workingDir: _packageDir);
    final String statusOutput = statusResult.stdout;
    if (statusOutput.isNotEmpty) {
      _print(
          "There are files in the package directory that haven't been saved in git. Refusing to publish these files:\n\n"
          '$statusOutput\n'
          'If the directory should be clean, you can run `git clean -xdf && git reset --hard HEAD` to wipe all local changes.');
      throw ToolExit(1);
    }
  }

  Future<String> _verifyRemote(String remote) async {
    final ProcessResult remoteInfo = await processRunner.runAndExitOnError(
        'git', <String>['remote', 'get-url', remote],
        workingDir: _packageDir);
    return remoteInfo.stdout;
  }

  Future<void> _publish() async {
    final List<String> publishFlags = argResults[_pubFlagsOption];
    _print(
        'Running `pub publish ${publishFlags.join(' ')}` in ${_packageDir.absolute.path}...\n');
    final Process publish = await processRunner.start(
        'flutter', <String>['pub', 'publish'] + publishFlags,
        workingDirectory: _packageDir);
    publish.stdout
        .transform(utf8.decoder)
        .listen((String data) => _print(data));
    publish.stderr
        .transform(utf8.decoder)
        .listen((String data) => _print(data));
    _stdinSubscription = _stdin
        .transform(utf8.decoder)
        .listen((String data) => publish.stdin.writeln(data));
    final int result = await publish.exitCode;
    if (result != 0) {
      _print('Publish failed. Exiting.');
      throw ToolExit(result);
    }
  }

  String _getTag() {
    final File pubspecFile =
        fileSystem.file(p.join(_packageDir.path, 'pubspec.yaml'));
    final YamlMap pubspecYaml = loadYaml(pubspecFile.readAsStringSync());
    final String name = pubspecYaml['name'];
    final String version = pubspecYaml['version'];
    // We should have failed to publish if these were unset.
    assert(name.isNotEmpty && version.isNotEmpty);
    return _tagFormat
        .replaceAll('%PACKAGE%', name)
        .replaceAll('%VERSION%', version);
  }

  Future<void> _pushTagToRemote(
      {@required String remote,
      @required String tag,
      @required String remoteUrl}) async {
    assert(remote != null && tag != null && remoteUrl != null);
    _print('Ready to push $tag to $remoteUrl (y/n)?');
    final String input = _stdin.readLineSync();
    if (input.toLowerCase() != 'y') {
      _print('Tag push canceled.');
      throw ToolExit(1);
    }

    await processRunner.runAndExitOnError('git', <String>['push', remote, tag],
        workingDir: packagesDir);
  }
}
