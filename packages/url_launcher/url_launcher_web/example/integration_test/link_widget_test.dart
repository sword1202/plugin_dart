// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_web/src/link.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Link Widget', () {
    testWidgets('creates anchor with correct attributes',
        (WidgetTester tester) async {
      final Uri uri = Uri.parse('http://foobar/example?q=1');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: WebLinkDelegate(TestLinkInfo(
          uri: uri,
          target: LinkTarget.blank,
          builder: (BuildContext context, FollowLink? followLink) {
            return Container(width: 100, height: 100);
          },
        )),
      ));
      // Platform view creation happens asynchronously.
      await tester.pumpAndSettle();

      final html.Element anchor = _findSingleAnchor();
      expect(anchor.getAttribute('href'), uri.toString());
      expect(anchor.getAttribute('target'), '_blank');

      final Uri uri2 = Uri.parse('http://foobar2/example?q=2');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: WebLinkDelegate(TestLinkInfo(
          uri: uri2,
          target: LinkTarget.self,
          builder: (BuildContext context, FollowLink? followLink) {
            return Container(width: 100, height: 100);
          },
        )),
      ));
      await tester.pumpAndSettle();

      // Check that the same anchor has been updated.
      expect(anchor.getAttribute('href'), uri2.toString());
      expect(anchor.getAttribute('target'), '_self');
    });

    testWidgets('sizes itself correctly', (WidgetTester tester) async {
      final Key containerKey = GlobalKey();
      final Uri uri = Uri.parse('http://foobar');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints.tight(Size(100.0, 100.0)),
            child: WebLinkDelegate(TestLinkInfo(
              uri: uri,
              target: LinkTarget.blank,
              builder: (BuildContext context, FollowLink? followLink) {
                return Container(
                  key: containerKey,
                  child: SizedBox(width: 50.0, height: 50.0),
                );
              },
            )),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final Size containerSize = tester.getSize(find.byKey(containerKey));
      // The Stack widget inserted by the `WebLinkDelegate` shouldn't loosen the
      // constraints before passing them to the inner container. So the inner
      // container should respect the tight constraints given by the ancestor
      // `ConstrainedBox` widget.
      expect(containerSize.width, 100.0);
      expect(containerSize.height, 100.0);
    });

    // See: https://github.com/flutter/plugins/pull/3522#discussion_r574703724
    testWidgets('uri can be null', (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: WebLinkDelegate(TestLinkInfo(
          uri: null,
          target: LinkTarget.defaultTarget,
          builder: (BuildContext context, FollowLink? followLink) {
            return Container(width: 100, height: 100);
          },
        )),
      ));
      // Platform view creation happens asynchronously.
      await tester.pumpAndSettle();

      final html.Element anchor = _findSingleAnchor();
      expect(anchor.hasAttribute('href'), false);
    });
  });
}

html.Element _findSingleAnchor() {
  final List<html.Element> foundAnchors = <html.Element>[];
  for (final html.Element anchor in html.document.querySelectorAll('a')) {
    if (hasProperty(anchor, linkViewIdProperty)) {
      foundAnchors.add(anchor);
    }
  }

  // Search inside platform views with shadow roots as well.
  for (final html.Element platformView
      in html.document.querySelectorAll('flt-platform-view')) {
    final html.ShadowRoot shadowRoot = platformView.shadowRoot!;
    if (shadowRoot != null) {
      for (final html.Element anchor in shadowRoot.querySelectorAll('a')) {
        if (hasProperty(anchor, linkViewIdProperty)) {
          foundAnchors.add(anchor);
        }
      }
    }
  }

  return foundAnchors.single;
}

class TestLinkInfo extends LinkInfo {
  @override
  final LinkWidgetBuilder builder;

  @override
  final Uri? uri;

  @override
  final LinkTarget target;

  @override
  bool get isDisabled => uri == null;

  TestLinkInfo({
    required this.uri,
    required this.target,
    required this.builder,
  });
}
