// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_selector_linux/file_selector_linux.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FileSelectorLinux plugin;
  late List<MethodCall> log;

  setUp(() {
    plugin = FileSelectorLinux();
    log = <MethodCall>[];
    _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
        .defaultBinaryMessenger
        .setMockMethodCallHandler(
      plugin.channel,
      (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      },
    );
  });

  test('registers instance', () {
    FileSelectorLinux.registerWith();
    expect(FileSelectorPlatform.instance, isA<FileSelectorLinux>());
  });

  group('#openFile', () {
    test('passes the accepted type groups correctly', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'text',
        extensions: <String>['txt'],
        mimeTypes: <String>['text/plain'],
        macUTIs: <String>['public.text'],
      );

      const XTypeGroup groupTwo = XTypeGroup(
        label: 'image',
        extensions: <String>['jpg'],
        mimeTypes: <String>['image/jpg'],
        macUTIs: <String>['public.image'],
        webWildCards: <String>['image/*'],
      );

      await plugin.openFile(acceptedTypeGroups: <XTypeGroup>[group, groupTwo]);

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'acceptedTypeGroups': <Map<String, dynamic>>[
            <String, Object>{
              'label': 'text',
              'extensions': <String>['*.txt'],
              'mimeTypes': <String>['text/plain'],
            },
            <String, Object>{
              'label': 'image',
              'extensions': <String>['*.jpg'],
              'mimeTypes': <String>['image/jpg'],
            },
          ],
          'initialDirectory': null,
          'confirmButtonText': null,
          'multiple': false,
        },
      );
    });

    test('passes initialDirectory correctly', () async {
      await plugin.openFile(initialDirectory: '/example/directory');

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'initialDirectory': '/example/directory',
          'confirmButtonText': null,
          'multiple': false,
        },
      );
    });

    test('passes confirmButtonText correctly', () async {
      await plugin.openFile(confirmButtonText: 'Open File');

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'initialDirectory': null,
          'confirmButtonText': 'Open File',
          'multiple': false,
        },
      );
    });

    test('throws for a type group that does not support Linux', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'images',
        webWildCards: <String>['images/*'],
      );

      await expectLater(
          plugin.openFile(acceptedTypeGroups: <XTypeGroup>[group]),
          throwsArgumentError);
    });

    test('passes a wildcard group correctly', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'any',
      );

      await plugin.openFile(acceptedTypeGroups: <XTypeGroup>[group]);

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'acceptedTypeGroups': <Map<String, dynamic>>[
            <String, Object>{
              'label': 'any',
              'extensions': <String>['*'],
            },
          ],
          'initialDirectory': null,
          'confirmButtonText': null,
          'multiple': false,
        },
      );
    });
  });

  group('#openFiles', () {
    test('passes the accepted type groups correctly', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'text',
        extensions: <String>['txt'],
        mimeTypes: <String>['text/plain'],
        macUTIs: <String>['public.text'],
      );

      const XTypeGroup groupTwo = XTypeGroup(
        label: 'image',
        extensions: <String>['jpg'],
        mimeTypes: <String>['image/jpg'],
        macUTIs: <String>['public.image'],
        webWildCards: <String>['image/*'],
      );

      await plugin.openFiles(acceptedTypeGroups: <XTypeGroup>[group, groupTwo]);

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'acceptedTypeGroups': <Map<String, dynamic>>[
            <String, Object>{
              'label': 'text',
              'extensions': <String>['*.txt'],
              'mimeTypes': <String>['text/plain'],
            },
            <String, Object>{
              'label': 'image',
              'extensions': <String>['*.jpg'],
              'mimeTypes': <String>['image/jpg'],
            },
          ],
          'initialDirectory': null,
          'confirmButtonText': null,
          'multiple': true,
        },
      );
    });

    test('passes initialDirectory correctly', () async {
      await plugin.openFiles(initialDirectory: '/example/directory');

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'initialDirectory': '/example/directory',
          'confirmButtonText': null,
          'multiple': true,
        },
      );
    });

    test('passes confirmButtonText correctly', () async {
      await plugin.openFiles(confirmButtonText: 'Open File');

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'initialDirectory': null,
          'confirmButtonText': 'Open File',
          'multiple': true,
        },
      );
    });

    test('throws for a type group that does not support Linux', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'images',
        webWildCards: <String>['images/*'],
      );

      await expectLater(
          plugin.openFile(acceptedTypeGroups: <XTypeGroup>[group]),
          throwsArgumentError);
    });

    test('passes a wildcard group correctly', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'any',
      );

      await plugin.openFile(acceptedTypeGroups: <XTypeGroup>[group]);

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'acceptedTypeGroups': <Map<String, dynamic>>[
            <String, Object>{
              'label': 'any',
              'extensions': <String>['*'],
            },
          ],
          'initialDirectory': null,
          'confirmButtonText': null,
          'multiple': false,
        },
      );
    });
  });

  group('#getSavePath', () {
    test('passes the accepted type groups correctly', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'text',
        extensions: <String>['txt'],
        mimeTypes: <String>['text/plain'],
        macUTIs: <String>['public.text'],
      );

      const XTypeGroup groupTwo = XTypeGroup(
        label: 'image',
        extensions: <String>['jpg'],
        mimeTypes: <String>['image/jpg'],
        macUTIs: <String>['public.image'],
        webWildCards: <String>['image/*'],
      );

      await plugin
          .getSavePath(acceptedTypeGroups: <XTypeGroup>[group, groupTwo]);

      expectMethodCall(
        log,
        'getSavePath',
        arguments: <String, dynamic>{
          'acceptedTypeGroups': <Map<String, dynamic>>[
            <String, Object>{
              'label': 'text',
              'extensions': <String>['*.txt'],
              'mimeTypes': <String>['text/plain'],
            },
            <String, Object>{
              'label': 'image',
              'extensions': <String>['*.jpg'],
              'mimeTypes': <String>['image/jpg'],
            },
          ],
          'initialDirectory': null,
          'suggestedName': null,
          'confirmButtonText': null,
        },
      );
    });

    test('passes initialDirectory correctly', () async {
      await plugin.getSavePath(initialDirectory: '/example/directory');

      expectMethodCall(
        log,
        'getSavePath',
        arguments: <String, dynamic>{
          'initialDirectory': '/example/directory',
          'suggestedName': null,
          'confirmButtonText': null,
        },
      );
    });

    test('passes confirmButtonText correctly', () async {
      await plugin.getSavePath(confirmButtonText: 'Open File');

      expectMethodCall(
        log,
        'getSavePath',
        arguments: <String, dynamic>{
          'initialDirectory': null,
          'suggestedName': null,
          'confirmButtonText': 'Open File',
        },
      );
    });

    test('throws for a type group that does not support Linux', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'images',
        webWildCards: <String>['images/*'],
      );

      await expectLater(
          plugin.openFile(acceptedTypeGroups: <XTypeGroup>[group]),
          throwsArgumentError);
    });

    test('passes a wildcard group correctly', () async {
      const XTypeGroup group = XTypeGroup(
        label: 'any',
      );

      await plugin.openFile(acceptedTypeGroups: <XTypeGroup>[group]);

      expectMethodCall(
        log,
        'openFile',
        arguments: <String, dynamic>{
          'acceptedTypeGroups': <Map<String, dynamic>>[
            <String, Object>{
              'label': 'any',
              'extensions': <String>['*'],
            },
          ],
          'initialDirectory': null,
          'confirmButtonText': null,
          'multiple': false,
        },
      );
    });
  });

  group('#getDirectoryPath', () {
    test('passes initialDirectory correctly', () async {
      await plugin.getDirectoryPath(initialDirectory: '/example/directory');

      expectMethodCall(
        log,
        'getDirectoryPath',
        arguments: <String, dynamic>{
          'initialDirectory': '/example/directory',
          'confirmButtonText': null,
        },
      );
    });
    test('passes confirmButtonText correctly', () async {
      await plugin.getDirectoryPath(confirmButtonText: 'Select Folder');

      expectMethodCall(
        log,
        'getDirectoryPath',
        arguments: <String, dynamic>{
          'initialDirectory': null,
          'confirmButtonText': 'Select Folder',
        },
      );
    });
  });

  group('#getDirectoryPaths', () {
    test('passes initialDirectory correctly', () async {
      await plugin.getDirectoryPaths(initialDirectory: '/example/directory');

      expectMethodCall(
        log,
        'getDirectoryPath',
        arguments: <String, dynamic>{
          'initialDirectory': '/example/directory',
          'confirmButtonText': null,
          'multiple': true,
        },
      );
    });
    test('passes confirmButtonText correctly', () async {
      await plugin.getDirectoryPaths(
          confirmButtonText: 'Select one or mode folders');

      expectMethodCall(
        log,
        'getDirectoryPath',
        arguments: <String, dynamic>{
          'initialDirectory': null,
          'confirmButtonText': 'Select one or mode folders',
          'multiple': true,
        },
      );
    });
    test('passes multiple flag correctly', () async {
      await plugin.getDirectoryPaths();

      expectMethodCall(
        log,
        'getDirectoryPath',
        arguments: <String, dynamic>{
          'initialDirectory': null,
          'confirmButtonText': null,
          'multiple': true,
        },
      );
    });
  });
}

void expectMethodCall(
  List<MethodCall> log,
  String methodName, {
  Map<String, dynamic>? arguments,
}) {
  expect(log, <Matcher>[isMethodCall(methodName, arguments: arguments)]);
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
T? _ambiguate<T>(T? value) => value;
