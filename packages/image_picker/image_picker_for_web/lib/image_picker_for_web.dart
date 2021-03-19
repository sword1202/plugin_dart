// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:meta/meta.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

final String _kImagePickerInputsDomId = '__image_picker_web-file-input';
final String _kAcceptImageMimeType = 'image/*';
final String _kAcceptVideoMimeType = 'video/3gpp,video/x-m4v,video/mp4,video/*';

/// The web implementation of [ImagePickerPlatform].
///
/// This class implements the `package:image_picker` functionality for the web.
class ImagePickerPlugin extends ImagePickerPlatform {
  final ImagePickerPluginTestOverrides? _overrides;
  bool get _hasOverrides => _overrides != null;

  late html.Element _target;

  /// A constructor that allows tests to override the function that creates file inputs.
  ImagePickerPlugin({
    @visibleForTesting ImagePickerPluginTestOverrides? overrides,
  }) : _overrides = overrides {
    _target = _ensureInitialized(_kImagePickerInputsDomId);
  }

  /// Registers this class as the default instance of [ImagePickerPlatform].
  static void registerWith(Registrar registrar) {
    ImagePickerPlatform.instance = ImagePickerPlugin();
  }

  /// Returns a [PickedFile] with the image that was picked.
  ///
  /// The `source` argument controls where the image comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Note that the `maxWidth`, `maxHeight` and `imageQuality` arguments are not supported on the web. If any of these arguments is supplied, it'll be silently ignored by the web version of the plugin.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// If no images were picked, the return value is null.
  @override
  Future<PickedFile> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    String? capture = computeCaptureAttribute(source, preferredCameraDevice);
    return pickFile(accept: _kAcceptImageMimeType, capture: capture);
  }

  /// Returns a [PickedFile] containing the video that was picked.
  ///
  /// The [source] argument controls where the video comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Note that the `maxDuration` argument is not supported on the web. If the argument is supplied, it'll be silently ignored by the web version of the plugin.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// If no images were picked, the return value is null.
  @override
  Future<PickedFile> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    String? capture = computeCaptureAttribute(source, preferredCameraDevice);
    return pickFile(accept: _kAcceptVideoMimeType, capture: capture);
  }

  /// Injects a file input with the specified accept+capture attributes, and
  /// returns the PickedFile that the user selected locally.
  ///
  /// `capture` is only supported in mobile browsers.
  /// See https://caniuse.com/#feat=html-media-capture
  @visibleForTesting
  Future<PickedFile> pickFile({
    String? accept,
    String? capture,
  }) {
    html.FileUploadInputElement input =
        createInputElement(accept, capture) as html.FileUploadInputElement;
    _injectAndActivate(input);
    return _getSelectedFile(input);
  }

  // DOM methods

  /// Converts plugin configuration into a proper value for the `capture` attribute.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#capture
  @visibleForTesting
  String? computeCaptureAttribute(ImageSource source, CameraDevice device) {
    if (source == ImageSource.camera) {
      return (device == CameraDevice.front) ? 'user' : 'environment';
    }
    return null;
  }

  html.File? _getFileFromInput(html.FileUploadInputElement input) {
    if (_hasOverrides) {
      return _overrides!.getFileFromInput(input);
    }
    return input.files?.first;
  }

  /// Handles the OnChange event from a FileUploadInputElement object
  /// Returns the objectURL of the selected file.
  String? _handleOnChangeEvent(html.Event event) {
    final html.FileUploadInputElement input =
        event.target as html.FileUploadInputElement;
    final html.File? file = _getFileFromInput(input);

    if (file != null) {
      return html.Url.createObjectUrl(file);
    }
    return null;
  }

  /// Monitors an <input type="file"> and returns the selected file.
  Future<PickedFile> _getSelectedFile(html.FileUploadInputElement input) {
    final Completer<PickedFile> _completer = Completer<PickedFile>();
    // Observe the input until we can return something
    input.onChange.first.then((event) {
      final objectUrl = _handleOnChangeEvent(event);
      if (!_completer.isCompleted && objectUrl != null) {
        _completer.complete(PickedFile(objectUrl));
      }
    });
    input.onError.first.then((event) {
      if (!_completer.isCompleted) {
        _completer.completeError(event);
      }
    });
    // Note that we don't bother detaching from these streams, since the
    // "input" gets re-created in the DOM every time the user needs to
    // pick a file.
    return _completer.future;
  }

  /// Initializes a DOM container where we can host input elements.
  html.Element _ensureInitialized(String id) {
    var target = html.querySelector('#${id}');
    if (target == null) {
      final html.Element targetElement =
          html.Element.tag('flt-image-picker-inputs')..id = id;

      html.querySelector('body')!.children.add(targetElement);
      target = targetElement;
    }
    return target;
  }

  /// Creates an input element that accepts certain file types, and
  /// allows to `capture` from the device's cameras (where supported)
  @visibleForTesting
  html.Element createInputElement(String? accept, String? capture) {
    if (_hasOverrides) {
      return _overrides!.createInputElement(accept, capture);
    }

    html.Element element = html.FileUploadInputElement()..accept = accept;

    if (capture != null) {
      element.setAttribute('capture', capture);
    }

    return element;
  }

  /// Injects the file input element, and clicks on it
  void _injectAndActivate(html.Element element) {
    _target.children.clear();
    _target.children.add(element);
    element.click();
  }
}

// Some tools to override behavior for unit-testing
/// A function that creates a file input with the passed in `accept` and `capture` attributes.
@visibleForTesting
typedef OverrideCreateInputFunction = html.Element Function(
  String? accept,
  String? capture,
);

/// A function that extracts a [html.File] from the file `input` passed in.
@visibleForTesting
typedef OverrideExtractFilesFromInputFunction = html.File Function(
  html.Element? input,
);

/// Overrides for some of the functionality above.
@visibleForTesting
class ImagePickerPluginTestOverrides {
  /// Override the creation of the input element.
  late OverrideCreateInputFunction createInputElement;

  /// Override the extraction of the selected file from an input element.
  late OverrideExtractFilesFromInputFunction getFileFromInput;
}
