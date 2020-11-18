## 0.1.0+8

* Update `package:google_maps_flutter_platform_interface` to `^1.0.5`.
* Add support for `fromBitmap` BitmapDescriptors. [Issue](https://github.com/flutter/flutter/issues/66622).

## 0.1.0+7

* Substitute `undefined_prefixed_name: ignore` analyzer setting by a `dart:ui` shim with conditional exports. [Issue](https://github.com/flutter/flutter/issues/69309).

## 0.1.0+6

* Ensure a single `InfoWindow` is shown at a time. [Issue](https://github.com/flutter/flutter/issues/67380).

## 0.1.0+5

* Update `package:google_maps` to `^3.4.5`.
* Fix `GoogleMapController.getLatLng()`. [Issue](https://github.com/flutter/flutter/issues/67606).
* Make `InfoWindow` contents clickable so `onTap` works as advertised. [Issue](https://github.com/flutter/flutter/issues/67289).
* Fix `InfoWindow` snippets when converting initial markers. [Issue](https://github.com/flutter/flutter/issues/67854).

## 0.1.0+4

* Update `package:sanitize_html` to `^1.4.1` to prevent [a crash](https://github.com/flutter/flutter/issues/67854) when InfoWindow title/snippet have links.

## 0.1.0+3

* Fix crash when converting initial polylines and polygons. [Issue](https://github.com/flutter/flutter/issues/65152).
* Correctly convert Colors when rendering polylines, polygons and circles. [Issue](https://github.com/flutter/flutter/issues/67032).

## 0.1.0+2

* Fix crash when converting Markers with icon explicitly set to null. [Issue](https://github.com/flutter/flutter/issues/64938).

## 0.1.0+1

* Port e2e tests to use the new integration_test package.

## 0.1.0

* First open-source version
