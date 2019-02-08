## 0.4.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.4.0

* **Breaking Change** Removal of base detector class `FirebaseVisionDetector`.
* **Breaking Change** Removal of `TextRecognizer.detectInImage()`. Pleas use `TextRecognizer.processImage()`.
* **Breaking Change** Changed `FaceDetector.detectInImage()` to `FaceDetector.processImage()`.

## 0.3.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.2.1

* Add capability to create image from bytes.

## 0.2.0+2

* Fix bug with empty text object.
* Fix bug with crash from passing nil to map.

## 0.2.0+1

Bump Android dependencies to latest.

## 0.2.0

* **Breaking Change** Update TextDetector to TextRecognizer for android mlkit '17.0.0' and
firebase-ios-sdk '5.6.0'.
* Added CloudLabelDetector.

## 0.1.2

* Fix example imports so that publishing will be warning-free.

## 0.1.1

* Set pod version of Firebase/MLVision to avoid breaking changes.

## 0.1.0

* **Breaking Change** Add Barcode, Face, and Label on-device detectors.
* Remove close method.

## 0.0.2

* Bump Android and Firebase dependency versions.

## 0.0.1

* Initial release with text detector.
