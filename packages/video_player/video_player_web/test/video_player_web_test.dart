// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@TestOn('browser')

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player_web/video_player_web.dart';

void main() {
  group('VideoPlayer for Web', () {
    int textureId;

    setUp(() async {
      VideoPlayerPlatform.instance = VideoPlayerPlugin();
      textureId = await VideoPlayerPlatform.instance.create(
        DataSource(
            sourceType: DataSourceType.network,
            uri:
                'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
      );
    });

    test('$VideoPlayerPlugin is the live instance', () {
      expect(VideoPlayerPlatform.instance, isA<VideoPlayerPlugin>());
    });

    test('can init', () {
      expect(VideoPlayerPlatform.instance.init(), completes);
    });

    test('can create', () {
      expect(
          VideoPlayerPlatform.instance.create(
            DataSource(
                sourceType: DataSourceType.network,
                uri:
                    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
          ),
          completion(isNonZero));
    });

    test('can dispose', () {
      expect(VideoPlayerPlatform.instance.dispose(textureId), completes);
    });

    test('can set looping', () {
      expect(
          VideoPlayerPlatform.instance.setLooping(textureId, true), completes);
    });

    test('can play', () async {
      // Mute video to allow autoplay (See https://goo.gl/xX8pDD)
      await VideoPlayerPlatform.instance.setVolume(textureId, 0);
      expect(VideoPlayerPlatform.instance.play(textureId), completes);
    });

    test('can pause', () {
      expect(VideoPlayerPlatform.instance.pause(textureId), completes);
    });

    test('can set volume', () {
      expect(VideoPlayerPlatform.instance.setVolume(textureId, 0.8), completes);
    });

    test('can seek to position', () {
      expect(
          VideoPlayerPlatform.instance.seekTo(textureId, Duration(seconds: 1)),
          completes);
    });

    test('can get position', () {
      expect(VideoPlayerPlatform.instance.getPosition(textureId),
          completion(isInstanceOf<Duration>()));
    });

    test('can get video event stream', () {
      expect(VideoPlayerPlatform.instance.videoEventsFor(textureId),
          isInstanceOf<Stream<VideoEvent>>());
    });

    test('can build view', () {
      expect(VideoPlayerPlatform.instance.buildView(textureId),
          isInstanceOf<Widget>());
    });
  });
}
