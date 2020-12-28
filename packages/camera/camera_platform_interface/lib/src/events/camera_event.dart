// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../camera_platform_interface.dart';

/// Generic Event coming from the native side of Camera.
///
/// All [CameraEvent]s contain the `cameraId` that originated the event. This
/// should never be `null`.
///
/// This class is used as a base class for all the events that might be
/// triggered from a Camera, but it is never used directly as an event type.
///
/// Do NOT instantiate new events like `CameraEvent(cameraId)` directly,
/// use a specific class instead:
///
/// Do `class NewEvent extend CameraEvent` when creating your own events.
/// See below for examples: `CameraClosingEvent`, `CameraErrorEvent`...
/// These events are more semantic and more pleasant to use than raw generics.
/// They can be (and in fact, are) filtered by the `instanceof`-operator.
abstract class CameraEvent {
  /// The ID of the Camera this event is associated to.
  final int cameraId;

  /// Build a Camera Event, that relates a `cameraId`.
  ///
  /// The `cameraId` is the ID of the camera that triggered the event.
  CameraEvent(this.cameraId) : assert(cameraId != null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraEvent &&
          runtimeType == other.runtimeType &&
          cameraId == other.cameraId;

  @override
  int get hashCode => cameraId.hashCode;
}

/// An event fired when the camera has finished initializing.
class CameraInitializedEvent extends CameraEvent {
  /// The width of the preview in pixels.
  final double previewWidth;

  /// The height of the preview in pixels.
  final double previewHeight;

  /// The default exposure mode
  final ExposureMode exposureMode;

  /// Whether setting exposure points is supported.
  final bool exposurePointSupported;

  /// Build a CameraInitialized event triggered from the camera represented by
  /// `cameraId`.
  ///
  /// The `previewWidth` represents the width of the generated preview in pixels.
  /// The `previewHeight` represents the height of the generated preview in pixels.
  CameraInitializedEvent(
    int cameraId,
    this.previewWidth,
    this.previewHeight,
    this.exposureMode,
    this.exposurePointSupported,
  ) : super(cameraId);

  /// Converts the supplied [Map] to an instance of the [CameraInitializedEvent]
  /// class.
  CameraInitializedEvent.fromJson(Map<String, dynamic> json)
      : previewWidth = json['previewWidth'],
        previewHeight = json['previewHeight'],
        exposureMode = deserializeExposureMode(json['exposureMode']),
        exposurePointSupported = json['exposurePointSupported'],
        super(json['cameraId']);

  /// Converts the [CameraInitializedEvent] instance into a [Map] instance that
  /// can be serialized to JSON.
  Map<String, dynamic> toJson() => {
        'cameraId': cameraId,
        'previewWidth': previewWidth,
        'previewHeight': previewHeight,
        'exposureMode': serializeExposureMode(exposureMode),
        'exposurePointSupported': exposurePointSupported,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CameraInitializedEvent &&
          runtimeType == other.runtimeType &&
          previewWidth == other.previewWidth &&
          previewHeight == other.previewHeight &&
          exposureMode == other.exposureMode &&
          exposurePointSupported == other.exposurePointSupported;

  @override
  int get hashCode =>
      super.hashCode ^
      previewWidth.hashCode ^
      previewHeight.hashCode ^
      exposureMode.hashCode ^
      exposurePointSupported.hashCode;
}

/// An event fired when the resolution preset of the camera has changed.
class CameraResolutionChangedEvent extends CameraEvent {
  /// The capture width in pixels.
  final double captureWidth;

  /// The capture height in pixels.
  final double captureHeight;

  /// Build a CameraResolutionChanged event triggered from the camera
  /// represented by `cameraId`.
  ///
  /// The `captureWidth` represents the width of the resulting image in pixels.
  /// The `captureHeight` represents the height of the resulting image in pixels.
  CameraResolutionChangedEvent(
    int cameraId,
    this.captureWidth,
    this.captureHeight,
  ) : super(cameraId);

  /// Converts the supplied [Map] to an instance of the
  /// [CameraResolutionChangedEvent] class.
  CameraResolutionChangedEvent.fromJson(Map<String, dynamic> json)
      : captureWidth = json['captureWidth'],
        captureHeight = json['captureHeight'],
        super(json['cameraId']);

  /// Converts the [CameraResolutionChangedEvent] instance into a [Map] instance
  /// that can be serialized to JSON.
  Map<String, dynamic> toJson() => {
        'cameraId': cameraId,
        'captureWidth': captureWidth,
        'captureHeight': captureHeight,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraResolutionChangedEvent &&
          super == (other) &&
          runtimeType == other.runtimeType &&
          captureWidth == other.captureWidth &&
          captureHeight == other.captureHeight;

  @override
  int get hashCode =>
      super.hashCode ^ captureWidth.hashCode ^ captureHeight.hashCode;
}

/// An event fired when the camera is going to close.
class CameraClosingEvent extends CameraEvent {
  /// Build a CameraClosing event triggered from the camera represented by
  /// `cameraId`.
  CameraClosingEvent(int cameraId) : super(cameraId);

  /// Converts the supplied [Map] to an instance of the [CameraClosingEvent]
  /// class.
  CameraClosingEvent.fromJson(Map<String, dynamic> json)
      : super(json['cameraId']);

  /// Converts the [CameraClosingEvent] instance into a [Map] instance that can
  /// be serialized to JSON.
  Map<String, dynamic> toJson() => {
        'cameraId': cameraId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == (other) &&
          other is CameraClosingEvent &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => super.hashCode;
}

/// An event fired when an error occured while operating the camera.
class CameraErrorEvent extends CameraEvent {
  /// Description of the error.
  final String description;

  /// Build a CameraError event triggered from the camera represented by
  /// `cameraId`.
  ///
  /// The `description` represents the error occured on the camera.
  CameraErrorEvent(int cameraId, this.description) : super(cameraId);

  /// Converts the supplied [Map] to an instance of the [CameraErrorEvent]
  /// class.
  CameraErrorEvent.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        super(json['cameraId']);

  /// Converts the [CameraErrorEvent] instance into a [Map] instance that can be
  /// serialized to JSON.
  Map<String, dynamic> toJson() => {
        'cameraId': cameraId,
        'description': description,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == (other) &&
          other is CameraErrorEvent &&
          runtimeType == other.runtimeType &&
          description == other.description;

  @override
  int get hashCode => super.hashCode ^ description.hashCode;
}
