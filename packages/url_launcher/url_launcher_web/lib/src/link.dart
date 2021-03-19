// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher_platform_interface/link.dart';

/// The unique identifier for the view type to be used for link platform views.
const String linkViewType = '__url_launcher::link';

/// The name of the property used to set the viewId on the DOM element.
const String linkViewIdProperty = '__url_launcher::link::viewId';

/// Signature for a function that takes a unique [id] and creates an HTML element.
typedef HtmlViewFactory = html.Element Function(int viewId);

/// Factory that returns the link DOM element for each unique view id.
HtmlViewFactory get linkViewFactory => LinkViewController._viewFactory;

/// The delegate for building the [Link] widget on the web.
///
/// It uses a platform view to render an anchor element in the DOM.
class WebLinkDelegate extends StatefulWidget {
  /// Creates a delegate for the given [link].
  const WebLinkDelegate(this.link);

  /// Information about the link built by the app.
  final LinkInfo link;

  @override
  WebLinkDelegateState createState() => WebLinkDelegateState();
}

/// The link delegate used on the web platform.
///
/// For external URIs, it lets the browser do its thing. For app route names, it
/// pushes the route name to the framework.
class WebLinkDelegateState extends State<WebLinkDelegate> {
  late LinkViewController _controller;

  @override
  void didUpdateWidget(WebLinkDelegate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.link.uri != oldWidget.link.uri) {
      _controller.setUri(widget.link.uri);
    }
    if (widget.link.target != oldWidget.link.target) {
      _controller.setTarget(widget.link.target);
    }
  }

  Future<void> _followLink() {
    LinkViewController.registerHitTest(_controller);
    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.link.builder(
          context,
          widget.link.isDisabled ? null : _followLink,
        ),
        Positioned.fill(
          child: PlatformViewLink(
            viewType: linkViewType,
            onCreatePlatformView: (PlatformViewCreationParams params) {
              _controller = LinkViewController.fromParams(params, context);
              return _controller
                ..setUri(widget.link.uri)
                ..setTarget(widget.link.target);
            },
            surfaceFactory:
                (BuildContext context, PlatformViewController controller) {
              return PlatformViewSurface(
                controller: controller,
                gestureRecognizers:
                    Set<Factory<OneSequenceGestureRecognizer>>(),
                hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Controls link views.
class LinkViewController extends PlatformViewController {
  /// Creates a [LinkViewController] instance with the unique [viewId].
  LinkViewController(this.viewId, this.context) {
    if (_instances.isEmpty) {
      // This is the first controller being created, attach the global click
      // listener.
      _clickSubscription = html.window.onClick.listen(_onGlobalClick);
    }
    _instances[viewId] = this;
  }

  /// Creates and initializes a [LinkViewController] instance with the given
  /// platform view [params].
  factory LinkViewController.fromParams(
    PlatformViewCreationParams params,
    BuildContext context,
  ) {
    final int viewId = params.id;
    final LinkViewController controller = LinkViewController(viewId, context);
    controller._initialize().then((_) {
      params.onPlatformViewCreated(viewId);
    });
    return controller;
  }

  static Map<int, LinkViewController> _instances = <int, LinkViewController>{};

  static html.Element _viewFactory(int viewId) {
    return _instances[viewId]!._element;
  }

  static int? _hitTestedViewId;

  static late StreamSubscription _clickSubscription;

  static void _onGlobalClick(html.MouseEvent event) {
    final int? viewId = getViewIdFromTarget(event);
    _instances[viewId]?._onDomClick(event);
    // After the DOM click event has been received, clean up the hit test state
    // so we can start fresh on the next click.
    unregisterHitTest();
  }

  /// Call this method to indicate that a hit test has been registered for the
  /// given [controller].
  ///
  /// The [onClick] callback is invoked when the anchor element receives a
  /// `click` from the browser.
  static void registerHitTest(LinkViewController controller) {
    _hitTestedViewId = controller.viewId;
  }

  /// Removes all information about previously registered hit tests.
  static void unregisterHitTest() {
    _hitTestedViewId = null;
  }

  @override
  final int viewId;

  /// The context of the [Link] widget that created this controller.
  final BuildContext context;

  late html.Element _element;
  bool get _isInitialized => _element != null;

  Future<void> _initialize() async {
    _element = html.Element.tag('a');
    setProperty(_element, linkViewIdProperty, viewId);
    _element.style
      ..opacity = '0'
      ..display = 'block'
      ..cursor = 'unset';

    // This is recommended on MDN:
    // - https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a#attr-target
    _element.setAttribute('rel', 'noreferrer noopener');

    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': linkViewType,
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
  }

  void _onDomClick(html.MouseEvent event) {
    final bool isHitTested = _hitTestedViewId == viewId;
    if (!isHitTested) {
      // There was no hit test registered for this click. This means the click
      // landed on the anchor element but not on the underlying widget. In this
      // case, we prevent the browser from following the click.
      event.preventDefault();
      return;
    }

    if (_uri != null && _uri!.hasScheme) {
      // External links will be handled by the browser, so we don't have to do
      // anything.
      return;
    }

    // A uri that doesn't have a scheme is an internal route name. In this
    // case, we push it via Flutter's navigation system instead of letting the
    // browser handle it.
    event.preventDefault();
    final String routeName = _uri.toString();
    pushRouteNameToFramework(context, routeName);
  }

  Uri? _uri;

  /// Set the [Uri] value for this link.
  ///
  /// When Uri is null, the `href` attribute of the link is removed.
  void setUri(Uri? uri) {
    assert(_isInitialized);
    _uri = uri;
    if (uri == null) {
      _element.removeAttribute('href');
    } else {
      _element.setAttribute('href', uri.toString());
    }
  }

  /// Set the [LinkTarget] value for this link.
  void setTarget(LinkTarget target) {
    assert(_isInitialized);
    _element.setAttribute('target', _getHtmlTarget(target));
  }

  String _getHtmlTarget(LinkTarget target) {
    switch (target) {
      case LinkTarget.defaultTarget:
      case LinkTarget.self:
        return '_self';
      case LinkTarget.blank:
        return '_blank';
      default:
        throw Exception('Unknown LinkTarget value $target.');
    }
  }

  @override
  Future<void> clearFocus() async {
    // Currently this does nothing on Flutter Web.
    // TODO(het): Implement this. See https://github.com/flutter/flutter/issues/39496
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    // We do not dispatch pointer events to HTML views because they may contain
    // cross-origin iframes, which only accept user-generated events.
  }

  @override
  Future<void> dispose() async {
    if (_isInitialized) {
      assert(_instances[viewId] == this);
      _instances.remove(viewId);
      if (_instances.isEmpty) {
        await _clickSubscription.cancel();
      }
      await SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}

/// Finds the view id of the DOM element targeted by the [event].
int? getViewIdFromTarget(html.Event event) {
  final html.Element? linkElement = getLinkElementFromTarget(event);
  if (linkElement != null) {
    return getProperty(linkElement, linkViewIdProperty);
  }
  return null;
}

/// Finds the targeted DOM element by the [event].
///
/// It handles the case where the target element is inside a shadow DOM too.
html.Element? getLinkElementFromTarget(html.Event event) {
  final html.EventTarget? target = event.target;
  if (target != null && target is html.Element) {
    if (isLinkElement(target)) {
      return target;
    }
    if (target.shadowRoot != null) {
      final html.Node? child = target.shadowRoot!.lastChild;
      if (child != null && child is html.Element && isLinkElement(child)) {
        return child;
      }
    }
  }
  return null;
}

/// Checks if the given [element] is a link that was created by
/// [LinkViewController].
bool isLinkElement(html.Element? element) {
  return element != null &&
      element.tagName == 'A' &&
      hasProperty(element, linkViewIdProperty);
}
