#!/bin/bash

# This script contains the list of plugins migrated to nnbd
# that should be excluded from testing on Flutter stable until
# null-safe is available on stable.

readonly NNBD_PLUGINS_LIST=(
  "android_intent"
  "battery"
  "connectivity"
  "cross_file"
  "device_info"
  "file_selector"
  "flutter_plugin_android_lifecycle"
  "flutter_webview"
  "google_sign_in"
  "local_auth"
  "path_provider"
  "package_info"
  "plugin_platform_interface"
  "share"
  "shared_preferences"
  "url_launcher"
  "video_player"
  "webview_flutter"
  "image_picker"
)

# This list contains the list of plugins that have *not* been
# migrated to nnbd, and conflict with those that have when
# building the all plugins app. This list should be kept empty.

readonly NON_NNBD_PLUGINS_LIST=(
  # "android_alarm_manager"
  "camera"
  # "google_maps_flutter"
  # "image_picker"
  # "in_app_purchase"
  # "quick_actions"
  # "sensors"
  # "wifi_info_flutter"
)

export EXCLUDED_PLUGINS_FROM_STABLE=$(IFS=, ; echo "${NNBD_PLUGINS_LIST[*]}")
export EXCLUDED_PLUGINS_FROM_MASTER=$(IFS=, ; echo "${NON_NNBD_PLUGINS_LIST[*]}")
