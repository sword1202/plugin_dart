// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome') // Uses web-only Flutter SDK

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cross_file/cross_file.dart';

final String expectedStringContents = 'Hello, world!';
final Uint8List bytes = Uint8List.fromList(utf8.encode(expectedStringContents));
final html.File textFile = html.File([bytes], 'hello.txt');
final String textFileUrl = html.Url.createObjectUrl(textFile);

void main() {
  group('Create with an objectUrl', () {
    final file = XFile(textFileUrl);

    test('Can be read as a string', () async {
      expect(await file.readAsString(), equals(expectedStringContents));
    });
    test('Can be read as bytes', () async {
      expect(await file.readAsBytes(), equals(bytes));
    });

    test('Can be read as a stream', () async {
      expect(await file.openRead().first, equals(bytes));
    });

    test('Stream can be sliced', () async {
      expect(await file.openRead(2, 5).first, equals(bytes.sublist(2, 5)));
    });
  });

  group('Create from data', () {
    final file = XFile.fromData(bytes);

    test('Can be read as a string', () async {
      expect(await file.readAsString(), equals(expectedStringContents));
    });
    test('Can be read as bytes', () async {
      expect(await file.readAsBytes(), equals(bytes));
    });

    test('Can be read as a stream', () async {
      expect(await file.openRead().first, equals(bytes));
    });

    test('Stream can be sliced', () async {
      expect(await file.openRead(2, 5).first, equals(bytes.sublist(2, 5)));
    });
  });

  group('saveTo(..)', () {
    final String CrossFileDomElementId = '__x_file_dom_element';

    group('CrossFile saveTo(..)', () {
      test('creates a DOM container', () async {
        XFile file = XFile.fromData(bytes);

        await file.saveTo('');

        final container = html.querySelector('#${CrossFileDomElementId}');

        expect(container, isNotNull);
      });

      test('create anchor element', () async {
        XFile file = XFile.fromData(bytes, name: textFile.name);

        await file.saveTo('path');

        final container = html.querySelector('#${CrossFileDomElementId}');
        final html.AnchorElement element =
            container?.children.firstWhere((element) => element.tagName == 'A')
                as html.AnchorElement;

        // if element is not found, the `firstWhere` call will throw StateError.
        expect(element.href, file.path);
        expect(element.download, file.name);
      });

      test('anchor element is clicked', () async {
        final mockAnchor = html.AnchorElement();

        CrossFileTestOverrides overrides = CrossFileTestOverrides(
          createAnchorElement: (_, __) => mockAnchor,
        );

        XFile file =
            XFile.fromData(bytes, name: textFile.name, overrides: overrides);

        bool clicked = false;
        mockAnchor.onClick.listen((event) => clicked = true);

        await file.saveTo('path');

        expect(clicked, true);
      });
    });
  });
}
