// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:file_selector_web/file_selector_web.dart';
import 'package:file_selector_web/src/dom_helper.dart';

void main() {
  group('FileSelectorWeb', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    group('openFile', () {
      testWidgets('works', (WidgetTester _) async {
        final mockFile = createXFile('1001', 'identity.png');

        final mockDomHelper = MockDomHelper()
          ..setFiles([mockFile])
          ..expectAccept('.jpg,.jpeg,image/png,image/*')
          ..expectMultiple(false);

        final plugin = FileSelectorWeb(domHelper: mockDomHelper);

        final typeGroup = XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg'],
          mimeTypes: ['image/png'],
          webWildCards: ['image/*'],
        );

        final file = await plugin.openFile(acceptedTypeGroups: [typeGroup]);

        expect(file.name, mockFile.name);
        expect(await file.length(), 4);
        expect(await file.readAsString(), '1001');
        expect(await file.lastModified(), isNotNull);
      });
    });

    group('openFiles', () {
      testWidgets('works', (WidgetTester _) async {
        final mockFile1 = createXFile('123456', 'file1.txt');
        final mockFile2 = createXFile('', 'file2.txt');

        final mockDomHelper = MockDomHelper()
          ..setFiles([mockFile1, mockFile2])
          ..expectAccept('.txt')
          ..expectMultiple(true);

        final plugin = FileSelectorWeb(domHelper: mockDomHelper);

        final typeGroup = XTypeGroup(
          label: 'files',
          extensions: ['.txt'],
        );

        final files = await plugin.openFiles(acceptedTypeGroups: [typeGroup]);

        expect(files.length, 2);

        expect(files[0].name, mockFile1.name);
        expect(await files[0].length(), 6);
        expect(await files[0].readAsString(), '123456');
        expect(await files[0].lastModified(), isNotNull);

        expect(files[1].name, mockFile2.name);
        expect(await files[1].length(), 0);
        expect(await files[1].readAsString(), '');
        expect(await files[1].lastModified(), isNotNull);
      });
    });

    group('getSavePath', () {
      testWidgets('returns non-null', (WidgetTester _) async {
        final plugin = FileSelectorWeb();
        final savePath = plugin.getSavePath();
        expect(await savePath, isNotNull);
      });
    });
  });
}

class MockDomHelper implements DomHelper {
  List<XFile> _files = <XFile>[];
  String _expectedAccept = '';
  bool _expectedMultiple = false;

  @override
  Future<List<XFile>> getFiles({
    String accept = '',
    bool multiple = false,
    FileUploadInputElement? input,
  }) {
    expect(accept, _expectedAccept,
        reason: 'Expected "accept" value does not match.');
    expect(multiple, _expectedMultiple,
        reason: 'Expected "multiple" value does not match.');
    return Future.value(_files);
  }

  void setFiles(List<XFile> files) {
    _files = files;
  }

  void expectAccept(String accept) {
    _expectedAccept = accept;
  }

  void expectMultiple(bool multiple) {
    _expectedMultiple = multiple;
  }
}

XFile createXFile(String content, String name) {
  final data = Uint8List.fromList(content.codeUnits);
  return XFile.fromData(data, name: name, lastModified: DateTime.now());
}
