import 'dart:typed_data';
import 'package:meta/meta.dart';

import './base.dart';

/// A XFile is a cross-platform, simplified File abstraction.
///
/// It wraps the bytes of a selected file, and its (platform-dependant) path.
class XFile extends XFileBase {
  /// Construct a XFile object from its path.
  ///
  /// Optionally, this can be initialized with `bytes` and `length`
  /// so no http requests are performed to retrieve data later.
  ///
  /// `name` may be passed from the outside, for those cases where the effective
  /// `path` of the file doesn't match what the user sees when selecting it
  /// (like in web)
  XFile(
    String path, {
    String mimeType,
    String name,
    int length,
    Uint8List bytes,
    DateTime lastModified,
    @visibleForTesting XFileTestOverrides overrides,
  }) : super(path) {
    throw UnimplementedError(
        'XFile is not available in your current platform.');
  }

  /// Construct a XFile object from its data
  XFile.fromData(
    Uint8List bytes, {
    String mimeType,
    String name,
    int length,
    DateTime lastModified,
    String path,
    @visibleForTesting XFileTestOverrides overrides,
  }) : super(path) {
    throw UnimplementedError(
        'XFile is not available in your current platform.');
  }
}

/// Overrides some functions of XFile for testing purposes
@visibleForTesting
class XFileTestOverrides {
  /// For overriding the creation of the file input element.
  dynamic Function(String href, String suggestedName) createAnchorElement;

  /// Default constructor for overrides
  XFileTestOverrides({this.createAnchorElement});
}
