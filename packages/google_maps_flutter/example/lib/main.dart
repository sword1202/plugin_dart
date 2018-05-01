// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'animate_camera.dart';
import 'map_ui.dart';
import 'move_camera.dart';
import 'page.dart';
import 'place_marker.dart';

final List<Page> _allPages = <Page>[
  new MapUiPage(),
  new AnimateCameraPage(),
  new MoveCameraPage(),
  new PlaceMarkerPage(),
];

class MapsDemo extends StatelessWidget {
  void _pushPage(BuildContext context, Page page) {
    Navigator.of(context).push(new MaterialPageRoute<void>(
        builder: (_) => new Scaffold(
              appBar: new AppBar(title: new Text(page.title)),
              body: page,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: const Text('GoogleMaps examples')),
      body: new ListView.builder(
        itemCount: _allPages.length,
        itemBuilder: (_, int index) => new ListTile(
              leading: _allPages[index].leading,
              title: new Text(_allPages[index].title),
              onTap: () => _pushPage(context, _allPages[index]),
            ),
      ),
    );
  }
}

void main() {
  GoogleMapController.init();
  final List<NavigatorObserver> observers = <NavigatorObserver>[];
  for (Page p in _allPages) {
    observers.add(p.controller.overlayController);
  }
  runApp(new MaterialApp(home: new MapsDemo(), navigatorObservers: observers));
}
