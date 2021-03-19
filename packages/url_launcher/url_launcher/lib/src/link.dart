// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// A widget that renders a real link on the web, and uses WebViews in native
/// platforms to open links.
///
/// Example link to an external URL:
///
/// ```dart
/// Link(
///   uri: Uri.parse('https://flutter.dev'),
///   builder: (BuildContext context, FollowLink followLink) => ElevatedButton(
///     onPressed: followLink,
///     // ... other properties here ...
///   )},
/// );
/// ```
///
/// Example link to a route name within the app:
///
/// ```dart
/// Link(
///   uri: Uri.parse('/home'),
///   builder: (BuildContext context, FollowLink followLink) => ElevatedButton(
///     onPressed: followLink,
///     // ... other properties here ...
///   )},
/// );
/// ```
class Link extends StatelessWidget implements LinkInfo {
  /// Called at build time to construct the widget tree under the link.
  final LinkWidgetBuilder builder;

  /// The destination that this link leads to.
  final Uri? uri;

  /// The target indicating where to open the link.
  final LinkTarget target;

  /// Whether the link is disabled or not.
  bool get isDisabled => uri == null;

  /// Creates a widget that renders a real link on the web, and uses WebViews in
  /// native platforms to open links.
  Link({
    Key? key,
    required this.uri,
    this.target = LinkTarget.defaultTarget,
    required this.builder,
  }) : super(key: key);

  LinkDelegate get _effectiveDelegate {
    return UrlLauncherPlatform.instance.linkDelegate ??
        DefaultLinkDelegate.create;
  }

  @override
  Widget build(BuildContext context) {
    return _effectiveDelegate(this);
  }
}

/// The default delegate used on non-web platforms.
///
/// For external URIs, it uses url_launche APIs. For app route names, it uses
/// event channel messages to instruct the framework to push the route name.
class DefaultLinkDelegate extends StatelessWidget {
  /// Creates a delegate for the given [link].
  const DefaultLinkDelegate(this.link);

  /// Given a [link], creates an instance of [DefaultLinkDelegate].
  ///
  /// This is a static method so it can be used as a tear-off.
  static DefaultLinkDelegate create(LinkInfo link) {
    return DefaultLinkDelegate(link);
  }

  /// Information about the link built by the app.
  final LinkInfo link;

  bool get _useWebView {
    if (link.target == LinkTarget.self) return true;
    if (link.target == LinkTarget.blank) return false;
    return false;
  }

  Future<void> _followLink(BuildContext context) async {
    if (!link.uri!.hasScheme) {
      // A uri that doesn't have a scheme is an internal route name. In this
      // case, we push it via Flutter's navigation system instead of letting the
      // browser handle it.
      final String routeName = link.uri.toString();
      await pushRouteNameToFramework(context, routeName);
      return;
    }

    // At this point, we know that the link is external. So we use the `launch`
    // API to open the link.
    final String urlString = link.uri.toString();
    if (await canLaunch(urlString)) {
      await launch(
        urlString,
        forceSafariVC: _useWebView,
        forceWebView: _useWebView,
      );
    } else {
      FlutterError.reportError(FlutterErrorDetails(
        exception: 'Could not launch link $urlString',
        stack: StackTrace.current,
        library: 'url_launcher',
        context: ErrorDescription('during launching a link'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return link.builder(
      context,
      link.isDisabled ? null : () => _followLink(context),
    );
  }
}
