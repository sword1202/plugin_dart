// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.androidalarmmanagerexample;

import androidx.annotation.NonNull;

public class DriverExtensionActivity extends MainActivity {
  @Override
  @NonNull
  public String getDartEntrypointFunctionName() {
    return "appMain";
  }
}
