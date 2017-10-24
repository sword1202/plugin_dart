// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

/// Provides device and operating system information.
class DeviceInfoPlugin {
  /// Channel used to communicate to native code.
  static const MethodChannel channel =
      const MethodChannel('plugins.flutter.io/device_info');

  DeviceInfoPlugin();

  /// This information does not change from call to call. Cache it.
  AndroidDeviceInfo _cachedAndroidDeviceInfo;

  /// Information derived from `android.os.Build`.
  ///
  /// See: https://developer.android.com/reference/android/os/Build.html
  Future<AndroidDeviceInfo> get androidInfo async =>
      _cachedAndroidDeviceInfo ??= AndroidDeviceInfo
          ._fromJson(await channel.invokeMethod('getAndroidDeviceInfo'));

  /// This information does not change from call to call. Cache it.
  IosDeviceInfo _cachedIosDeviceInfo;

  /// Information derived from `UIDevice`.
  ///
  /// See: https://developer.apple.com/documentation/uikit/uidevice
  Future<IosDeviceInfo> get iosInfo async => _cachedIosDeviceInfo ??=
      IosDeviceInfo._fromJson(await channel.invokeMethod('getIosDeviceInfo'));
}

/// Information derived from `android.os.Build`.
///
/// See: https://developer.android.com/reference/android/os/Build.html
class AndroidDeviceInfo {
  AndroidDeviceInfo._({
    this.version,
    this.board,
    this.bootloader,
    this.brand,
    this.device,
    this.display,
    this.fingerprint,
    this.hardware,
    this.host,
    this.id,
    this.manufacturer,
    this.model,
    this.product,
    List<String> supported32BitAbis,
    List<String> supported64BitAbis,
    List<String> supportedAbis,
    this.tags,
    this.type,
    this.isPhysicalDevice,
  })
      : supported32BitAbis = new List<String>.unmodifiable(supported32BitAbis),
        supported64BitAbis = new List<String>.unmodifiable(supported64BitAbis),
        supportedAbis = new List<String>.unmodifiable(supportedAbis);

  /// Android operating system version values derived from `android.os.Build.VERSION`.
  final AndroidBuildVersion version;

  /// The name of the underlying board, like "goldfish".
  final String board;

  /// The system bootloader version number.
  final String bootloader;

  /// The consumer-visible brand with which the product/hardware will be associated, if any.
  final String brand;

  /// The name of the industrial design.
  final String device;

  /// A build ID string meant for displaying to the user.
  final String display;

  /// A string that uniquely identifies this build.
  final String fingerprint;

  /// The name of the hardware (from the kernel command line or /proc).
  final String hardware;

  /// Hostname.
  final String host;

  /// Either a changelist number, or a label like "M4-rc20".
  final String id;

  /// The manufacturer of the product/hardware.
  final String manufacturer;

  /// The end-user-visible name for the end product.
  final String model;

  /// The name of the overall product.
  final String product;

  /// An ordered list of 32 bit ABIs supported by this device.
  final List<String> supported32BitAbis;

  /// An ordered list of 64 bit ABIs supported by this device.
  final List<String> supported64BitAbis;

  /// An ordered list of ABIs supported by this device.
  final List<String> supportedAbis;

  /// Comma-separated tags describing the build, like "unsigned,debug".
  final String tags;

  /// The type of build, like "user" or "eng".
  final String type;

  /// `false` if the application is running in an emulator, `true` otherwise.
  final bool isPhysicalDevice;

  /// Deserializes from the JSON message received from [_kChannel].
  static AndroidDeviceInfo _fromJson(Map<String, Object> json) {
    return new AndroidDeviceInfo._(
      version: AndroidBuildVersion._fromJson(json['version']),
      board: json['board'],
      bootloader: json['bootloader'],
      brand: json['brand'],
      device: json['device'],
      display: json['display'],
      fingerprint: json['fingerprint'],
      hardware: json['hardware'],
      host: json['host'],
      id: json['id'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      product: json['product'],
      supported32BitAbis: json['supported32BitAbis'],
      supported64BitAbis: json['supported64BitAbis'],
      supportedAbis: json['supportedAbis'],
      tags: json['tags'],
      type: json['type'],
      isPhysicalDevice: json['isPhysicalDevice'],
    );
  }
}

/// Version values of the current Android operating system build derived from
/// `android.os.Build.VERSION`.
///
/// See: https://developer.android.com/reference/android/os/Build.VERSION.html
class AndroidBuildVersion {
  AndroidBuildVersion._({
    this.baseOS,
    this.codename,
    this.incremental,
    this.previewSdkInt,
    this.release,
    this.sdkInt,
    this.securityPatch,
  });

  /// The base OS build the product is based on.
  final String baseOS;

  /// The current development codename, or the string "REL" if this is a release build.
  final String codename;

  /// The internal value used by the underlying source control to represent this build.
  final String incremental;

  /// The developer preview revision of a prerelease SDK.
  final int previewSdkInt;

  /// The user-visible version string.
  final String release;

  /// The user-visible SDK version of the framework; its possible values are defined in [AndroidBuildVersionCodes].
  final int sdkInt;

  /// The user-visible security patch level.
  final String securityPatch;

  /// Deserializes from the JSON message received from [_kChannel].
  static AndroidBuildVersion _fromJson(Map<String, Object> json) {
    return new AndroidBuildVersion._(
      baseOS: json['baseOS'],
      codename: json['codename'],
      incremental: json['incremental'],
      previewSdkInt: json['previewSdkInt'],
      release: json['release'],
      sdkInt: json['sdkInt'],
      securityPatch: json['securityPatch'],
    );
  }
}

/// Information derived from `UIDevice`.
///
/// See: https://developer.apple.com/documentation/uikit/uidevice
class IosDeviceInfo {
  IosDeviceInfo._({
    this.name,
    this.systemName,
    this.systemVersion,
    this.model,
    this.localizedModel,
    this.identifierForVendor,
    this.isPhysicalDevice,
    this.utsname,
  });

  /// Device name.
  final String name;

  /// The name of the current operating system.
  final String systemName;

  /// The current operating system version.
  final String systemVersion;

  /// Device model.
  final String model;

  /// Localized name of the device model.
  final String localizedModel;

  /// Unique UUID value identifying the current device.
  final String identifierForVendor;

  /// `false` if the application is running in a simulator, `true` otherwise.
  final bool isPhysicalDevice;

  /// Operating system information derived from `sys/utsname.h`.
  final IosUtsname utsname;

  /// Deserializes from the JSON message received from [_kChannel].
  static IosDeviceInfo _fromJson(Map<String, dynamic> json) {
    return new IosDeviceInfo._(
      name: json['name'],
      systemName: json['systemName'],
      systemVersion: json['systemVersion'],
      model: json['model'],
      localizedModel: json['localizedModel'],
      identifierForVendor: json['identifierForVendor'],
      isPhysicalDevice: json['isPhysicalDevice'] == 'true',
      utsname: IosUtsname._fromJson(json['utsname']),
    );
  }
}

/// Information derived from `utsname`.
/// See http://pubs.opengroup.org/onlinepubs/7908799/xsh/sysutsname.h.html for details.
class IosUtsname {
  IosUtsname._({
    this.sysname,
    this.nodename,
    this.release,
    this.version,
    this.machine,
  });

  /// Operating system name.
  final String sysname;

  /// Network node name.
  final String nodename;

  /// Release level.
  final String release;

  /// Version level.
  final String version;

  /// Hardware type (e.g. 'iPhone7,1' for iPhone 6 Plus).
  final String machine;

  /// Deserializes from the JSON message received from [_kChannel].
  static IosUtsname _fromJson(Map<String, dynamic> json) {
    return new IosUtsname._(
      sysname: json['sysname'],
      nodename: json['nodename'],
      release: json['release'],
      version: json['version'],
      machine: json['machine'],
    );
  }
}
