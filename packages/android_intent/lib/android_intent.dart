// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

const String _kChannelName = 'plugins.flutter.io/android_intent';

/// Flutter plugin for launching arbitrary Android Intents.
///
/// See [the official Android
/// documentation](https://developer.android.com/reference/android/content/Intent.html)
/// for more information on how to use Intents.
class AndroidIntent {
  /// Builds an Android intent with the following parameters
  /// [action] refers to the action parameter of the intent.
  /// [flags] is the list of int that will be converted to native flags.
  /// [category] refers to the category of the intent, can be null.
  /// [data] refers to the string format of the URI that will be passed to
  /// intent.
  /// [arguments] is the map that will be converted into an extras bundle and
  /// passed to the intent.
  /// [package] refers to the package parameter of the intent, can be null.
  /// [componentName] refers to the component name of the intent, can be null.
  /// If not null, then [package] but also be provided.
  const AndroidIntent({
    @required this.action,
    this.flags,
    this.category,
    this.data,
    this.arguments,
    this.package,
    this.componentName,
    Platform platform,
  })  : assert(action != null),
        _channel = const MethodChannel(_kChannelName),
        _platform = platform ?? const LocalPlatform();

  /// This constructor is only exposed for unit testing. Do not rely on this in
  /// app code, it may break without warning.
  @visibleForTesting
  AndroidIntent.private({
    @required this.action,
    @required Platform platform,
    @required MethodChannel channel,
    this.flags,
    this.category,
    this.data,
    this.arguments,
    this.package,
    this.componentName,
  })  : _channel = channel,
        _platform = platform;

  /// This is the general verb that the intent should attempt to do. This
  /// includes constants like `ACTION_VIEW`.
  ///
  /// See https://developer.android.com/reference/android/content/Intent.html#intent-structure.
  final String action;

  /// Constants that can be set on an intent to tweak how it is finally handled.
  /// Some of the constants are mirrored to Dart via [Flag].
  ///
  /// See https://developer.android.com/reference/android/content/Intent.html#setFlags(int).
  final List<int> flags;

  /// An optional additional constant qualifying the given [action].
  ///
  /// See https://developer.android.com/reference/android/content/Intent.html#intent-structure.
  final String category;

  /// The Uri that the [action] is pointed towards.
  ///
  /// See https://developer.android.com/reference/android/content/Intent.html#intent-structure.
  final String data;

  /// The equivalent of `extras`, a generic `Bundle` of data that the Intent can
  /// carry. This is a slot for extraneous data that the listener may use.
  ///
  /// See https://developer.android.com/reference/android/content/Intent.html#intent-structure.
  final Map<String, dynamic> arguments;

  /// Sets the [data] to only resolve within this given package.
  ///
  /// See https://developer.android.com/reference/android/content/Intent.html#setPackage(java.lang.String).
  final String package;

  /// Set the exact `ComponentName` that should handle the intent. If this is
  /// set [package] should also be non-null.
  ///
  /// See https://developer.android.com/reference/android/content/Intent.html#setComponent(android.content.ComponentName).
  final String componentName;
  final MethodChannel _channel;
  final Platform _platform;

  bool _isPowerOfTwo(int x) {
    /* First x in the below expression is for the case when x is 0 */
    return x != 0 && ((x & (x - 1)) == 0);
  }

  /// This method is just visible for unit testing and should not be relied on.
  /// Its method signature may change at any time.
  @visibleForTesting
  int convertFlags(List<int> flags) {
    int finalValue = 0;
    for (int i = 0; i < flags.length; i++) {
      if (!_isPowerOfTwo(flags[i])) {
        throw ArgumentError.value(flags[i], 'flag\'s value must be power of 2');
      }
      finalValue |= flags[i];
    }
    return finalValue;
  }

  /// Launch the intent.
  ///
  /// This works only on Android platforms.
  Future<void> launch() async {
    if (!_platform.isAndroid) {
      return;
    }
    final Map<String, dynamic> args = <String, dynamic>{'action': action};
    if (flags != null) {
      args['flags'] = convertFlags(flags);
    }
    if (category != null) {
      args['category'] = category;
    }
    if (data != null) {
      args['data'] = data;
    }
    if (arguments != null) {
      args['arguments'] = arguments;
    }
    if (package != null) {
      args['package'] = package;
      if (componentName != null) {
        args['componentName'] = componentName;
      }
    }
    await _channel.invokeMethod<void>('launch', args);
  }
}
