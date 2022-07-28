// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import 'src/messages.g.dart';

/// An implementation of [FileSelectorPlatform] for Windows.
class FileSelectorWindows extends FileSelectorPlatform {
  final FileSelectorApi _hostApi = FileSelectorApi();

  /// Registers the Windows implementation.
  static void registerWith() {
    FileSelectorPlatform.instance = FileSelectorWindows();
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _hostApi.showOpenDialog(
        SelectionOptions(
          allowMultiple: false,
          selectFolders: false,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        confirmButtonText);
    return paths.isEmpty ? null : XFile(paths.first!);
  }

  @override
  Future<List<XFile>> openFiles({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _hostApi.showOpenDialog(
        SelectionOptions(
          allowMultiple: true,
          selectFolders: false,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        confirmButtonText);
    return paths.map((String? path) => XFile(path!)).toList();
  }

  @override
  Future<String?> getSavePath({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? suggestedName,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _hostApi.showSaveDialog(
        SelectionOptions(
          allowMultiple: false,
          selectFolders: false,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        suggestedName,
        confirmButtonText);
    return paths.isEmpty ? null : paths.first!;
  }

  @override
  Future<String?> getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _hostApi.showOpenDialog(
        SelectionOptions(
          allowMultiple: false,
          selectFolders: true,
          allowedTypes: <TypeGroup>[],
        ),
        initialDirectory,
        confirmButtonText);
    return paths.isEmpty ? null : paths.first!;
  }
}

List<TypeGroup> _typeGroupsFromXTypeGroups(List<XTypeGroup>? xtypes) {
  return (xtypes ?? <XTypeGroup>[]).map((XTypeGroup xtype) {
    if (!xtype.allowsAny && (xtype.extensions?.isEmpty ?? true)) {
      throw ArgumentError('Provided type group $xtype does not allow '
          'all files, but does not set any of the Windows-supported filter '
          'categories. "extensions" must be non-empty for Windows if '
          'anything is non-empty.');
    }
    return TypeGroup(
        label: xtype.label ?? '', extensions: xtype.extensions ?? <String>[]);
  }).toList();
}
