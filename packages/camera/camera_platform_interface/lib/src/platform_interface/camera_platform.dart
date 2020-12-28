// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_platform_interface/src/method_channel/method_channel_camera.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of camera must implement.
///
/// Platform implementations should extend this class rather than implement it as `camera`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [CameraPlatform] methods.
abstract class CameraPlatform extends PlatformInterface {
  /// Constructs a CameraPlatform.
  CameraPlatform() : super(token: _token);

  static final Object _token = Object();

  static CameraPlatform _instance = MethodChannelCamera();

  /// The default instance of [CameraPlatform] to use.
  ///
  /// Defaults to [MethodChannelCamera].
  static CameraPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [CameraPlatform] when they register themselves.
  static set instance(CameraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Completes with a list of available cameras.
  Future<List<CameraDescription>> availableCameras() {
    throw UnimplementedError('availableCameras() is not implemented.');
  }

  /// Creates an uninitialized camera instance and returns the cameraId.
  Future<int> createCamera(
    CameraDescription cameraDescription,
    ResolutionPreset resolutionPreset, {
    bool enableAudio,
  }) {
    throw UnimplementedError('createCamera() is not implemented.');
  }

  /// Initializes the camera on the device.
  Future<void> initializeCamera(int cameraId) {
    throw UnimplementedError('initializeCamera() is not implemented.');
  }

  /// The camera has been initialized
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    throw UnimplementedError('onCameraInitialized() is not implemented.');
  }

  /// The camera's resolution has changed
  Stream<CameraResolutionChangedEvent> onCameraResolutionChanged(int cameraId) {
    throw UnimplementedError('onResolutionChanged() is not implemented.');
  }

  /// The camera started to close.
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) {
    throw UnimplementedError('onCameraClosing() is not implemented.');
  }

  /// The camera experienced an error.
  Stream<CameraErrorEvent> onCameraError(int cameraId) {
    throw UnimplementedError('onCameraError() is not implemented.');
  }

  /// Captures an image and returns the file where it was saved.
  Future<XFile> takePicture(int cameraId) {
    throw UnimplementedError('takePicture() is not implemented.');
  }

  /// Prepare the capture session for video recording.
  Future<void> prepareForVideoRecording() {
    throw UnimplementedError('prepareForVideoRecording() is not implemented.');
  }

  /// Starts a video recording.
  ///
  /// The length of the recording can be limited by specifying the [maxVideoDuration].
  /// By default no maximum duration is specified,
  /// meaning the recording will continue until manually stopped.
  /// The video is returned as a [XFile] after calling [stopVideoRecording].
  Future<void> startVideoRecording(int cameraId, {Duration maxVideoDuration}) {
    throw UnimplementedError('startVideoRecording() is not implemented.');
  }

  /// Stops the video recording and returns the file where it was saved.
  Future<XFile> stopVideoRecording(int cameraId) {
    throw UnimplementedError('stopVideoRecording() is not implemented.');
  }

  /// Pause video recording.
  Future<void> pauseVideoRecording(int cameraId) {
    throw UnimplementedError('pauseVideoRecording() is not implemented.');
  }

  /// Resume video recording after pausing.
  Future<void> resumeVideoRecording(int cameraId) {
    throw UnimplementedError('resumeVideoRecording() is not implemented.');
  }

  /// Sets the flash mode for the selected camera.
  Future<void> setFlashMode(int cameraId, FlashMode mode) {
    throw UnimplementedError('setFlashMode() is not implemented.');
  }

  /// Gets the maximum supported zoom level for the selected camera.
  Future<double> getMaxZoomLevel(int cameraId) {
    throw UnimplementedError('getMaxZoomLevel() is not implemented.');
  }

  /// Gets the minimum supported zoom level for the selected camera.
  Future<double> getMinZoomLevel(int cameraId) {
    throw UnimplementedError('getMinZoomLevel() is not implemented.');
  }

  /// Set the zoom level for the selected camera.
  ///
  /// The supplied [zoom] value should be between 1.0 and the maximum supported
  /// zoom level returned by the `getMaxZoomLevel`. Throws an `CameraException`
  /// when an illegal zoom level is supplied.
  Future<void> setZoomLevel(int cameraId, double zoom) {
    throw UnimplementedError('setZoomLevel() is not implemented.');
  }

  /// Returns a widget showing a live camera preview.
  Widget buildPreview(int cameraId) {
    throw UnimplementedError('buildView() has not been implemented.');
  }

  /// Releases the resources of this camera.
  Future<void> dispose(int cameraId) {
    throw UnimplementedError('dispose() is not implemented.');
  }
}
