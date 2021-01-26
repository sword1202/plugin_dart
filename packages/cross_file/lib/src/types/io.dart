// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import './base.dart';

/// A CrossFile backed by a dart:io File.
class XFile extends XFileBase {
  final File _file;
  final String? mimeType;
  final DateTime? _lastModified;
  int? _length;

  final Uint8List? _bytes;

  /// Construct a CrossFile object backed by a dart:io File.
  XFile(
    String path, {
    this.mimeType,
    String? name,
    int? length,
    Uint8List? bytes,
    DateTime? lastModified,
  })  : _file = File(path),
        _bytes = null,
        _lastModified = lastModified,
        super(path);

  /// Construct an CrossFile from its data
  XFile.fromData(
    Uint8List bytes, {
    this.mimeType,
    String? path,
    String? name,
    int? length,
    DateTime? lastModified,
  })  : _bytes = bytes,
        _file = File(path ?? ''),
        _length = length,
        _lastModified = lastModified,
        super(path) {
    if (length == null) {
      _length = bytes.length;
    }
  }

  @override
  Future<DateTime> lastModified() {
    if (_lastModified != null) {
      return Future.value(_lastModified);
    }
    return _file.lastModified();
  }

  @override
  Future<void> saveTo(String path) async {
    File fileToSave = File(path);
    await fileToSave.writeAsBytes(_bytes ?? (await readAsBytes()));
    await fileToSave.create();
  }

  @override
  String get path {
    return _file.path;
  }

  @override
  String get name {
    return _file.path.split(Platform.pathSeparator).last;
  }

  @override
  Future<int> length() {
    if (_length != null) {
      return Future.value(_length);
    }
    return _file.length();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    if (_bytes != null) {
      return Future.value(String.fromCharCodes(_bytes!));
    }
    return _file.readAsString(encoding: encoding);
  }

  @override
  Future<Uint8List> readAsBytes() {
    if (_bytes != null) {
      return Future.value(_bytes);
    }
    return _file.readAsBytes();
  }

  Stream<Uint8List> _getBytes(int? start, int? end) async* {
    final bytes = _bytes!;
    yield bytes.sublist(start ?? 0, end ?? bytes.length);
  }

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    if (_bytes != null) {
      return _getBytes(start, end);
    } else {
      return _file
          .openRead(start ?? 0, end)
          .map((chunk) => Uint8List.fromList(chunk));
    }
  }
}
