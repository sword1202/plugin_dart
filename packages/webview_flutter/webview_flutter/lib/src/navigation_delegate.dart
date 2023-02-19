// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'webview_controller.dart';

/// Callbacks for accepting or rejecting navigation changes, and for tracking
/// the progress of navigation requests.
///
/// See [WebViewController.setNavigationDelegate].
///
/// ## Platform-Specific Features
/// This class contains an underlying implementation provided by the current
/// platform. Once a platform implementation is imported, the examples below
/// can be followed to use features provided by a platform's implementation.
///
/// {@macro webview_flutter.NavigationDelegate.fromPlatformCreationParams}
///
/// Below is an example of accessing the platform-specific implementation for
/// iOS and Android:
///
/// ```dart
/// final NavigationDelegate navigationDelegate = NavigationDelegate();
///
/// if (WebViewPlatform.instance is WebKitWebViewPlatform) {
///   final WebKitNavigationDelegate webKitDelegate =
///       navigationDelegate.platform as WebKitNavigationDelegate;
/// } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
///   final AndroidNavigationDelegate androidDelegate =
///       navigationDelegate.platform as AndroidNavigationDelegate;
/// }
/// ```
class NavigationDelegate {
  /// Constructs a [NavigationDelegate].
  NavigationDelegate({
    FutureOr<NavigationDecision> Function(NavigationRequest request)?
        onNavigationRequest,
    void Function(String url)? onPageStarted,
    void Function(String url)? onPageFinished,
    void Function(int progress)? onProgress,
    void Function(WebResourceError error)? onWebResourceError,
  }) : this.fromPlatformCreationParams(
          const PlatformNavigationDelegateCreationParams(),
          onNavigationRequest: onNavigationRequest,
          onPageStarted: onPageStarted,
          onPageFinished: onPageFinished,
          onProgress: onProgress,
          onWebResourceError: onWebResourceError,
        );

  /// Constructs a [NavigationDelegate] from creation params for a specific
  /// platform.
  ///
  /// {@template webview_flutter.NavigationDelegate.fromPlatformCreationParams}
  /// Below is an example of setting platform-specific creation parameters for
  /// iOS and Android:
  ///
  /// ```dart
  /// PlatformNavigationDelegateCreationParams params =
  ///     const PlatformNavigationDelegateCreationParams();
  ///
  /// if (WebViewPlatform.instance is WebKitWebViewPlatform) {
  ///   params = WebKitNavigationDelegateCreationParams
  ///       .fromPlatformNavigationDelegateCreationParams(
  ///     params,
  ///   );
  /// } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
  ///   params = AndroidNavigationDelegateCreationParams
  ///       .fromPlatformNavigationDelegateCreationParams(
  ///     params,
  ///   );
  /// }
  ///
  /// final NavigationDelegate navigationDelegate =
  ///     NavigationDelegate.fromPlatformCreationParams(
  ///   params,
  /// );
  /// ```
  /// {@endtemplate}
  NavigationDelegate.fromPlatformCreationParams(
    PlatformNavigationDelegateCreationParams params, {
    FutureOr<NavigationDecision> Function(NavigationRequest request)?
        onNavigationRequest,
    void Function(String url)? onPageStarted,
    void Function(String url)? onPageFinished,
    void Function(int progress)? onProgress,
    void Function(WebResourceError error)? onWebResourceError,
  }) : this.fromPlatform(
          PlatformNavigationDelegate(params),
          onNavigationRequest: onNavigationRequest,
          onPageStarted: onPageStarted,
          onPageFinished: onPageFinished,
          onProgress: onProgress,
          onWebResourceError: onWebResourceError,
        );

  /// Constructs a [NavigationDelegate] from a specific platform implementation.
  NavigationDelegate.fromPlatform(
    this.platform, {
    this.onNavigationRequest,
    this.onPageStarted,
    this.onPageFinished,
    this.onProgress,
    this.onWebResourceError,
  }) {
    if (onNavigationRequest != null) {
      platform.setOnNavigationRequest(onNavigationRequest!);
    }
    if (onPageStarted != null) {
      platform.setOnPageStarted(onPageStarted!);
    }
    if (onPageFinished != null) {
      platform.setOnPageFinished(onPageFinished!);
    }
    if (onProgress != null) {
      platform.setOnProgress(onProgress!);
    }
    if (onWebResourceError != null) {
      platform.setOnWebResourceError(onWebResourceError!);
    }
  }

  /// Implementation of [PlatformNavigationDelegate] for the current platform.
  final PlatformNavigationDelegate platform;

  /// Invoked when a decision for a navigation request is pending.
  ///
  /// When a navigation is initiated by the WebView (e.g when a user clicks a
  /// link) this delegate is called and has to decide how to proceed with the
  /// navigation.
  ///
  /// *Important*: Some platforms may also trigger this callback from calls to
  /// [WebViewController.loadRequest].
  ///
  /// See [NavigationDecision].
  final NavigationRequestCallback? onNavigationRequest;

  /// Invoked when a page has started loading.
  final PageEventCallback? onPageStarted;

  /// Invoked when a page has finished loading.
  final PageEventCallback? onPageFinished;

  /// Invoked when a page is loading to report the progress.
  final ProgressCallback? onProgress;

  /// Invoked when a resource loading error occurred.
  final WebResourceErrorCallback? onWebResourceError;
}
