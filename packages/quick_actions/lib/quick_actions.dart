// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

const MethodChannel _kChannel =
    MethodChannel('plugins.flutter.io/quick_actions');

/// Handler for a quick action launch event.
///
/// The argument [type] corresponds to the [ShortcutItem]'s field.
typedef void QuickActionHandler(String type);

/// Home screen quick-action shortcut item.
class ShortcutItem {
  const ShortcutItem({
    @required this.type,
    @required this.localizedTitle,
    this.icon,
  });

  /// The identifier of this item; should be unique within the app.
  final String type;

  /// Localized title of the item.
  final String localizedTitle;

  /// Name of native resource (xcassets etc; NOT a Flutter asset) to be
  /// displayed as the icon for this item.
  final String icon;
}

/// Quick actions plugin.
class QuickActions {
  factory QuickActions() => _instance;

  @visibleForTesting
  QuickActions.withMethodChannel(this.channel);

  static final QuickActions _instance =
      QuickActions.withMethodChannel(_kChannel);

  final MethodChannel channel;

  /// Initializes this plugin.
  ///
  /// Call this once before any further interaction with the the plugin.
  void initialize(QuickActionHandler handler) async {
    channel.setMethodCallHandler((MethodCall call) async {
      assert(call.method == 'launch');
      handler(call.arguments);
    });
    runLaunchAction(handler);
  }

  void runLaunchAction(QuickActionHandler handler) async {
    final String action = await channel.invokeMethod<String>('getLaunchAction');
    if (action != null) {
      handler(action);
    }
  }

  /// Sets the [ShortcutItem]s to become the app's quick actions.
  Future<void> setShortcutItems(List<ShortcutItem> items) async {
    final List<Map<String, String>> itemsList =
        items.map(_serializeItem).toList();
    await channel.invokeMethod<void>('setShortcutItems', itemsList);
  }

  /// Removes all [ShortcutItem]s registered for the app.
  Future<void> clearShortcutItems() =>
      channel.invokeMethod<void>('clearShortcutItems');

  Map<String, String> _serializeItem(ShortcutItem item) {
    return <String, String>{
      'type': item.type,
      'localizedTitle': item.localizedTitle,
      'icon': item.icon,
    };
  }
}
