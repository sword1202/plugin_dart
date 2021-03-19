// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_plugin_tools/src/common.dart';
import 'package:flutter_plugin_tools/src/license_check_command.dart';
import 'package:test/test.dart';

void main() {
  group('$LicenseCheckCommand', () {
    CommandRunner<Null> runner;
    FileSystem fileSystem;
    List<String> printedMessages;
    Directory root;

    setUp(() {
      fileSystem = MemoryFileSystem();
      final Directory packagesDir =
          fileSystem.currentDirectory.childDirectory('packages');
      root = packagesDir.parent;

      printedMessages = <String>[];
      final LicenseCheckCommand command = LicenseCheckCommand(
        packagesDir,
        fileSystem,
        print: (Object message) => printedMessages.add(message.toString()),
      );
      runner =
          CommandRunner<Null>('license_test', 'Test for $LicenseCheckCommand');
      runner.addCommand(command);
    });

    /// Writes a copyright+license block to [file], defaulting to a standard
    /// block for this repository.
    ///
    /// [commentString] is added to the start of each line.
    /// [prefix] is added to the start of the entire block.
    /// [suffix] is added to the end of the entire block.
    void _writeLicense(
      File file, {
      String comment = '// ',
      String prefix = '',
      String suffix = '',
      String copyright =
          'Copyright 2013 The Flutter Authors. All rights reserved.',
      List<String> license = const <String>[
        'Use of this source code is governed by a BSD-style license that can be',
        'found in the LICENSE file.',
      ],
    }) {
      List<String> lines = ['$prefix$comment$copyright'];
      for (String line in license) {
        lines.add('$comment$line');
      }
      file.writeAsStringSync(lines.join('\n') + suffix + '\n');
    }

    test('looks at only expected extensions', () async {
      Map<String, bool> extensions = <String, bool>{
        'c': true,
        'cc': true,
        'cpp': true,
        'dart': true,
        'h': true,
        'html': true,
        'java': true,
        'json': false,
        'm': true,
        'md': false,
        'mm': true,
        'png': false,
        'swift': true,
        'sh': true,
        'yaml': false,
      };

      const String filenameBase = 'a_file';
      for (final String fileExtension in extensions.keys) {
        root.childFile('$filenameBase.$fileExtension').createSync();
      }

      try {
        await runner.run(<String>['license-check']);
      } on ToolExit {
        // Ignore failure; the files are empty so the check is expected to fail,
        // but this test isn't for that behavior.
      }

      extensions.forEach((String fileExtension, bool shouldCheck) {
        final Matcher logLineMatcher =
            contains('Checking $filenameBase.$fileExtension');
        expect(printedMessages,
            shouldCheck ? logLineMatcher : isNot(logLineMatcher));
      });
    });

    test('ignore list overrides extension matches', () async {
      List<String> ignoredFiles = <String>[
        // Ignored base names.
        'flutter_export_environment.sh',
        'GeneratedPluginRegistrant.java',
        'GeneratedPluginRegistrant.m',
        'generated_plugin_registrant.cc',
        'generated_plugin_registrant.cpp',
        // Ignored path suffixes.
        'foo.g.dart',
        'foo.mocks.dart',
        // Ignored files.
        'resource.h',
      ];

      for (final String name in ignoredFiles) {
        root.childFile(name).createSync();
      }

      await runner.run(<String>['license-check']);

      for (final String name in ignoredFiles) {
        expect(printedMessages, isNot(contains('Checking $name')));
      }
    });

    test('passes if all checked files have license blocks', () async {
      File checked = root.childFile('checked.cc');
      checked.createSync();
      _writeLicense(checked);
      File not_checked = root.childFile('not_checked.md');
      not_checked.createSync();

      await runner.run(<String>['license-check']);

      // Sanity check that the test did actually check a file.
      expect(printedMessages, contains('Checking checked.cc'));
      expect(printedMessages, contains('All source files passed validation!'));
    });

    test('handles the comment styles for all supported languages', () async {
      File file_a = root.childFile('file_a.cc');
      file_a.createSync();
      _writeLicense(file_a, comment: '// ');
      File file_b = root.childFile('file_b.sh');
      file_b.createSync();
      _writeLicense(file_b, comment: '# ');
      File file_c = root.childFile('file_c.html');
      file_c.createSync();
      _writeLicense(file_c, comment: '', prefix: '<!-- ', suffix: ' -->');

      await runner.run(<String>['license-check']);

      // Sanity check that the test did actually check the files.
      expect(printedMessages, contains('Checking file_a.cc'));
      expect(printedMessages, contains('Checking file_b.sh'));
      expect(printedMessages, contains('Checking file_c.html'));
      expect(printedMessages, contains('All source files passed validation!'));
    });

    test('fails if any checked files are missing license blocks', () async {
      File good_a = root.childFile('good.cc');
      good_a.createSync();
      _writeLicense(good_a);
      File good_b = root.childFile('good.h');
      good_b.createSync();
      _writeLicense(good_b);
      root.childFile('bad.cc').createSync();
      root.childFile('bad.h').createSync();

      await expectLater(() => runner.run(<String>['license-check']),
          throwsA(const TypeMatcher<ToolExit>()));

      // Failure should give information about the problematic files.
      expect(
          printedMessages,
          contains(
              'The license block for these files is missing or incorrect:'));
      expect(printedMessages, contains('  bad.cc'));
      expect(printedMessages, contains('  bad.h'));
      // Failure shouldn't print the success message.
      expect(printedMessages,
          isNot(contains('All source files passed validation!')));
    });

    test('fails if any checked files are missing just the copyright', () async {
      File good = root.childFile('good.cc');
      good.createSync();
      _writeLicense(good);
      File bad = root.childFile('bad.cc');
      bad.createSync();
      _writeLicense(bad, copyright: '');

      await expectLater(() => runner.run(<String>['license-check']),
          throwsA(const TypeMatcher<ToolExit>()));

      // Failure should give information about the problematic files.
      expect(
          printedMessages,
          contains(
              'The license block for these files is missing or incorrect:'));
      expect(printedMessages, contains('  bad.cc'));
      // Failure shouldn't print the success message.
      expect(printedMessages,
          isNot(contains('All source files passed validation!')));
    });

    test('fails if any checked files are missing just the license', () async {
      File good = root.childFile('good.cc');
      good.createSync();
      _writeLicense(good);
      File bad = root.childFile('bad.cc');
      bad.createSync();
      _writeLicense(bad, license: <String>[]);

      await expectLater(() => runner.run(<String>['license-check']),
          throwsA(const TypeMatcher<ToolExit>()));

      // Failure should give information about the problematic files.
      expect(
          printedMessages,
          contains(
              'The license block for these files is missing or incorrect:'));
      expect(printedMessages, contains('  bad.cc'));
      // Failure shouldn't print the success message.
      expect(printedMessages,
          isNot(contains('All source files passed validation!')));
    });

    test('fails if any third-party code is not in a third_party directory',
        () async {
      File thirdPartyFile = root.childFile('third_party.cc');
      thirdPartyFile.createSync();
      _writeLicense(thirdPartyFile, copyright: 'Copyright 2017 Someone Else');

      await expectLater(() => runner.run(<String>['license-check']),
          throwsA(const TypeMatcher<ToolExit>()));

      // Failure should give information about the problematic files.
      expect(
          printedMessages,
          contains(
              'The license block for these files is missing or incorrect:'));
      expect(printedMessages, contains('  third_party.cc'));
      // Failure shouldn't print the success message.
      expect(printedMessages,
          isNot(contains('All source files passed validation!')));
    });

    test('succeeds for third-party code in a third_party directory', () async {
      File thirdPartyFile = root
          .childDirectory('a_plugin')
          .childDirectory('lib')
          .childDirectory('src')
          .childDirectory('third_party')
          .childFile('file.cc');
      thirdPartyFile.createSync(recursive: true);
      _writeLicense(thirdPartyFile,
          copyright: 'Copyright 2017 Workiva Inc.',
          license: <String>[
            'Licensed under the Apache License, Version 2.0 (the "License");',
            'you may not use this file except in compliance with the License.'
          ]);

      await runner.run(<String>['license-check']);

      // Sanity check that the test did actually check the file.
      expect(printedMessages,
          contains('Checking a_plugin/lib/src/third_party/file.cc'));
      expect(printedMessages, contains('All source files passed validation!'));
    });

    test('fails for licenses that the tool does not expect', () async {
      File good = root.childFile('good.cc');
      good.createSync();
      _writeLicense(good);
      File bad = root.childDirectory('third_party').childFile('bad.cc');
      bad.createSync(recursive: true);
      _writeLicense(bad, license: <String>[
        'This program is free software: you can redistribute it and/or modify',
        'it under the terms of the GNU General Public License',
      ]);

      await expectLater(() => runner.run(<String>['license-check']),
          throwsA(const TypeMatcher<ToolExit>()));

      // Failure should give information about the problematic files.
      expect(
          printedMessages,
          contains(
              'No recognized license was found for the following third-party files:'));
      expect(printedMessages, contains('  third_party/bad.cc'));
      // Failure shouldn't print the success message.
      expect(printedMessages,
          isNot(contains('All source files passed validation!')));
    });

    test('Apache is not recognized for new authors without validation changes',
        () async {
      File good = root.childFile('good.cc');
      good.createSync();
      _writeLicense(good);
      File bad = root.childDirectory('third_party').childFile('bad.cc');
      bad.createSync(recursive: true);
      _writeLicense(
        bad,
        copyright: 'Copyright 2017 Some New Authors.',
          license: <String>[
            'Licensed under the Apache License, Version 2.0 (the "License");',
            'you may not use this file except in compliance with the License.'
          ],
      );

      await expectLater(() => runner.run(<String>['license-check']),
          throwsA(const TypeMatcher<ToolExit>()));

      // Failure should give information about the problematic files.
      expect(printedMessages,
          contains('No recognized license was found for the following third-party files:'));
      expect(printedMessages, contains('  third_party/bad.cc'));
      // Failure shouldn't print the success message.
      expect(printedMessages,
          isNot(contains('All source files passed validation!')));
    });

    test('passes if all first-party LICENSE files are correctly formatted',
        () async {
      File license = root.childFile('LICENSE');
      license.createSync();
      license.writeAsStringSync(_correctLicenseFileText);

      await runner.run(<String>['license-check']);

      // Sanity check that the test did actually check the file.
      expect(printedMessages, contains('Checking LICENSE'));
      expect(printedMessages, contains('All LICENSE files passed validation!'));
    });

    test('fails if any first-party LICENSE files are incorrectly formatted',
        () async {
      File license = root.childFile('LICENSE');
      license.createSync();
      license.writeAsStringSync(_incorrectLicenseFileText);

      await expectLater(() => runner.run(<String>['license-check']),
          throwsA(const TypeMatcher<ToolExit>()));

      expect(printedMessages,
          isNot(contains('All LICENSE files passed validation!')));
    });

    test('ignores third-party LICENSE format', () async {
      File license = root.childDirectory('third_party').childFile('LICENSE');
      license.createSync(recursive: true);
      license.writeAsStringSync(_incorrectLicenseFileText);

      await runner.run(<String>['license-check']);

      // The file shouldn't be checked.
      expect(printedMessages, isNot(contains('Checking third_party/LICENSE')));
      expect(printedMessages, contains('All LICENSE files passed validation!'));
    });
  });
}

const String _correctLicenseFileText =
    '''Copyright 2013 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';

// A common incorrect version created by copying text intended for a code file,
// with comment markers.
const String _incorrectLicenseFileText =
    '''// Copyright 2013 The Flutter Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';
