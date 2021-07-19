// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_web/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraOptions', () {
    test('serializes correctly', () {
      final cameraOptions = CameraOptions(
        audio: AudioConstraints(enabled: true),
        video: VideoConstraints(
          facingMode: FacingModeConstraint.exact(CameraType.user),
        ),
      );

      expect(
        cameraOptions.toJson(),
        equals({
          'audio': cameraOptions.audio.toJson(),
          'video': cameraOptions.video.toJson(),
        }),
      );
    });

    test('supports value equality', () {
      expect(
        CameraOptions(
          audio: AudioConstraints(enabled: false),
          video: VideoConstraints(
            facingMode: FacingModeConstraint(CameraType.environment),
            width: VideoSizeConstraint(minimum: 10, ideal: 15, maximum: 20),
            height: VideoSizeConstraint(minimum: 15, ideal: 20, maximum: 25),
            deviceId: 'deviceId',
          ),
        ),
        equals(
          CameraOptions(
            audio: AudioConstraints(enabled: false),
            video: VideoConstraints(
              facingMode: FacingModeConstraint(CameraType.environment),
              width: VideoSizeConstraint(minimum: 10, ideal: 15, maximum: 20),
              height: VideoSizeConstraint(minimum: 15, ideal: 20, maximum: 25),
              deviceId: 'deviceId',
            ),
          ),
        ),
      );
    });
  });

  group('AudioConstraints', () {
    test('serializes correctly', () {
      expect(
        AudioConstraints(enabled: true).toJson(),
        equals(true),
      );
    });

    test('supports value equality', () {
      expect(
        AudioConstraints(enabled: true),
        equals(AudioConstraints(enabled: true)),
      );
    });
  });

  group('VideoConstraints', () {
    test('serializes correctly', () {
      final videoConstraints = VideoConstraints(
        facingMode: FacingModeConstraint.exact(CameraType.user),
        width: VideoSizeConstraint(ideal: 100, maximum: 100),
        height: VideoSizeConstraint(ideal: 50, maximum: 50),
        deviceId: 'deviceId',
      );

      expect(
        videoConstraints.toJson(),
        equals({
          'facingMode': videoConstraints.facingMode!.toJson(),
          'width': videoConstraints.width!.toJson(),
          'height': videoConstraints.height!.toJson(),
          'deviceId': {
            'exact': 'deviceId',
          }
        }),
      );
    });

    test('supports value equality', () {
      expect(
        VideoConstraints(
          facingMode: FacingModeConstraint.exact(CameraType.environment),
          width: VideoSizeConstraint(minimum: 90, ideal: 100, maximum: 100),
          height: VideoSizeConstraint(minimum: 40, ideal: 50, maximum: 50),
          deviceId: 'deviceId',
        ),
        equals(
          VideoConstraints(
            facingMode: FacingModeConstraint.exact(CameraType.environment),
            width: VideoSizeConstraint(minimum: 90, ideal: 100, maximum: 100),
            height: VideoSizeConstraint(minimum: 40, ideal: 50, maximum: 50),
            deviceId: 'deviceId',
          ),
        ),
      );
    });
  });

  group('FacingModeConstraint', () {
    group('ideal', () {
      test(
          'serializes correctly '
          'for environment camera type', () {
        expect(
          FacingModeConstraint(CameraType.environment).toJson(),
          equals({'ideal': 'environment'}),
        );
      });

      test(
          'serializes correctly '
          'for user camera type', () {
        expect(
          FacingModeConstraint(CameraType.user).toJson(),
          equals({'ideal': 'user'}),
        );
      });

      test('supports value equality', () {
        expect(
          FacingModeConstraint(CameraType.user),
          equals(FacingModeConstraint(CameraType.user)),
        );
      });
    });

    group('exact', () {
      test(
          'serializes correctly '
          'for environment camera type', () {
        expect(
          FacingModeConstraint.exact(CameraType.environment).toJson(),
          equals({'exact': 'environment'}),
        );
      });

      test(
          'serializes correctly '
          'for user camera type', () {
        expect(
          FacingModeConstraint.exact(CameraType.user).toJson(),
          equals({'exact': 'user'}),
        );
      });

      test('supports value equality', () {
        expect(
          FacingModeConstraint.exact(CameraType.environment),
          equals(FacingModeConstraint.exact(CameraType.environment)),
        );
      });
    });
  });

  group('VideoSizeConstraint ', () {
    test('serializes correctly', () {
      expect(
        VideoSizeConstraint(
          minimum: 200,
          ideal: 400,
          maximum: 400,
        ).toJson(),
        equals({
          'min': 200,
          'ideal': 400,
          'max': 400,
        }),
      );
    });

    test('supports value equality', () {
      expect(
        VideoSizeConstraint(
          minimum: 100,
          ideal: 200,
          maximum: 300,
        ),
        equals(
          VideoSizeConstraint(
            minimum: 100,
            ideal: 200,
            maximum: 300,
          ),
        ),
      );
    });
  });
}
