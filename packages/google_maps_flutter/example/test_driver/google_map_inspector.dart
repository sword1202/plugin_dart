// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/services.dart';

/// Inspect Google Maps state using the platform SDK.
///
/// This class is primarily used for testing. The methods on this
/// class should call "getters" on the GoogleMap object or equivalent
/// on the platform side.
class GoogleMapInspector {
  GoogleMapInspector(this._channel);

  final MethodChannel _channel;

  Future<bool> isCompassEnabled() async {
    return await _channel.invokeMethod<bool>('map#isCompassEnabled');
  }
}
