// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' show getProperty;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps/google_maps.dart' as gmaps;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'resources/icon_image_base64.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MarkersController', () {
    late StreamController<MapEvent> events;
    late MarkersController controller;
    late gmaps.GMap map;

    setUp(() {
      events = StreamController<MapEvent>();
      controller = MarkersController(stream: events);
      map = gmaps.GMap(html.DivElement());
      controller.bindToMap(123, map);
    });

    testWidgets('addMarkers', (WidgetTester tester) async {
      final markers = {
        Marker(markerId: MarkerId('1')),
        Marker(markerId: MarkerId('2')),
      };

      controller.addMarkers(markers);

      expect(controller.markers.length, 2);
      expect(controller.markers, contains(MarkerId('1')));
      expect(controller.markers, contains(MarkerId('2')));
      expect(controller.markers, isNot(contains(MarkerId('66'))));
    });

    testWidgets('changeMarkers', (WidgetTester tester) async {
      final markers = {
        Marker(markerId: MarkerId('1')),
      };
      controller.addMarkers(markers);

      expect(controller.markers[MarkerId('1')]?.marker?.draggable, isFalse);

      // Update the marker with radius 10
      final updatedMarkers = {
        Marker(markerId: MarkerId('1'), draggable: true),
      };
      controller.changeMarkers(updatedMarkers);

      expect(controller.markers.length, 1);
      expect(controller.markers[MarkerId('1')]?.marker?.draggable, isTrue);
    });

    testWidgets('removeMarkers', (WidgetTester tester) async {
      final markers = {
        Marker(markerId: MarkerId('1')),
        Marker(markerId: MarkerId('2')),
        Marker(markerId: MarkerId('3')),
      };

      controller.addMarkers(markers);

      expect(controller.markers.length, 3);

      // Remove some markers...
      final markerIdsToRemove = {
        MarkerId('1'),
        MarkerId('3'),
      };

      controller.removeMarkers(markerIdsToRemove);

      expect(controller.markers.length, 1);
      expect(controller.markers, isNot(contains(MarkerId('1'))));
      expect(controller.markers, contains(MarkerId('2')));
      expect(controller.markers, isNot(contains(MarkerId('3'))));
    });

    testWidgets('InfoWindow show/hide', (WidgetTester tester) async {
      final markers = {
        Marker(
          markerId: MarkerId('1'),
          infoWindow: InfoWindow(title: "Title", snippet: "Snippet"),
        ),
      };

      controller.addMarkers(markers);

      expect(controller.markers[MarkerId('1')]?.infoWindowShown, isFalse);

      controller.showMarkerInfoWindow(MarkerId('1'));

      expect(controller.markers[MarkerId('1')]?.infoWindowShown, isTrue);

      controller.hideMarkerInfoWindow(MarkerId('1'));

      expect(controller.markers[MarkerId('1')]?.infoWindowShown, isFalse);
    });

    // https://github.com/flutter/flutter/issues/67380
    testWidgets('only single InfoWindow is visible',
        (WidgetTester tester) async {
      final markers = {
        Marker(
          markerId: MarkerId('1'),
          infoWindow: InfoWindow(title: "Title", snippet: "Snippet"),
        ),
        Marker(
          markerId: MarkerId('2'),
          infoWindow: InfoWindow(title: "Title", snippet: "Snippet"),
        ),
      };
      controller.addMarkers(markers);

      expect(controller.markers[MarkerId('1')]?.infoWindowShown, isFalse);
      expect(controller.markers[MarkerId('2')]?.infoWindowShown, isFalse);

      controller.showMarkerInfoWindow(MarkerId('1'));

      expect(controller.markers[MarkerId('1')]?.infoWindowShown, isTrue);
      expect(controller.markers[MarkerId('2')]?.infoWindowShown, isFalse);

      controller.showMarkerInfoWindow(MarkerId('2'));

      expect(controller.markers[MarkerId('1')]?.infoWindowShown, isFalse);
      expect(controller.markers[MarkerId('2')]?.infoWindowShown, isTrue);
    });

    // https://github.com/flutter/flutter/issues/66622
    testWidgets('markers with custom bitmap icon work',
        (WidgetTester tester) async {
      final bytes = Base64Decoder().convert(iconImageBase64);
      final markers = {
        Marker(
            markerId: MarkerId('1'), icon: BitmapDescriptor.fromBytes(bytes)),
      };

      controller.addMarkers(markers);

      expect(controller.markers.length, 1);
      expect(controller.markers[MarkerId('1')]?.marker?.icon, isNotNull);

      final blobUrl = getProperty(
        controller.markers[MarkerId('1')]!.marker!.icon!,
        'url',
      );

      expect(blobUrl, startsWith('blob:'));

      final response = await http.get(Uri.parse(blobUrl));

      expect(response.bodyBytes, bytes,
          reason:
              'Bytes from the Icon blob must match bytes used to create Marker');
    });

    // https://github.com/flutter/flutter/issues/67854
    testWidgets('InfoWindow snippet can have links',
        (WidgetTester tester) async {
      final markers = {
        Marker(
          markerId: MarkerId('1'),
          infoWindow: InfoWindow(
            title: 'title for test',
            snippet: '<a href="https://www.google.com">Go to Google >>></a>',
          ),
        ),
      };

      controller.addMarkers(markers);

      expect(controller.markers.length, 1);
      final content = controller.markers[MarkerId('1')]?.infoWindow?.content
          as html.HtmlElement;
      expect(content.innerHtml, contains('title for test'));
      expect(
          content.innerHtml,
          contains(
              '<a href="https://www.google.com">Go to Google &gt;&gt;&gt;</a>'));
    });

    // https://github.com/flutter/flutter/issues/67289
    testWidgets('InfoWindow content is clickable', (WidgetTester tester) async {
      final markers = {
        Marker(
          markerId: MarkerId('1'),
          infoWindow: InfoWindow(
            title: 'title for test',
            snippet: 'some snippet',
          ),
        ),
      };

      controller.addMarkers(markers);

      expect(controller.markers.length, 1);
      final content = controller.markers[MarkerId('1')]?.infoWindow?.content
          as html.HtmlElement;

      content.click();

      final event = await events.stream.first;

      expect(event, isA<InfoWindowTapEvent>());
      expect((event as InfoWindowTapEvent).value, equals(MarkerId('1')));
    });
  });
}
