#!/bin/bash

# This script builds the app in flutter/plugins/example/all_plugins to make
# sure all first party plugins can be compiled together.

# So that users can run this script from anywhere and it will work as expected.
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
readonly REPO_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"
check_changed_packages > /dev/null

readonly EXCLUDED_PLUGINS_LIST=(
  "connectivity_macos"
  "connectivity_platform_interface"
  "connectivity_web"
  "flutter_plugin_android_lifecycle"
  "google_sign_in_platform_interface"
  "google_sign_in_web"
  "instrumentation_adapter"
  "plugin_platform_interface"
  "shared_preferences_macos"
  "shared_preferences_platform_interface"
  "shared_preferences_web"
  "url_launcher_macos"
  "url_launcher_platform_interface"
  "url_launcher_web"
  "video_player_platform_interface"
  "video_player_web"
)
# Comma-separated string of the list above
readonly EXCLUDED=$(IFS=, ; echo "${EXCLUDED_PLUGINS_LIST[*]}")

(cd "$REPO_DIR" && pub global run flutter_plugin_tools all-plugins-app --exclude $EXCLUDED)

function error() {
  echo "$@" 1>&2
}

failures=0

for version in "debug" "release"; do
  (cd $REPO_DIR/all_plugins && flutter build $@ --$version)

  if [ $? -eq 0 ]; then
    echo "Successfully built $version all_plugins app."
    echo "All first party plugins compile together."
  else
    error "Failed to build $version all_plugins app."
    if [[ "${#CHANGED_PACKAGE_LIST[@]}" == 0 ]]; then
      error "There was a failure to compile all first party plugins together, but there were no changes detected in packages."
    else
      error "Changes to the following packages may prevent all first party plugins from compiling together:"
      for package in "${CHANGED_PACKAGE_LIST[@]}"; do
        error "$package"
      done
      echo ""
    fi
    failures=$(($failures + 1))
  fi
done

rm -rf $REPO_DIR/all_plugins/
exit $failures
