## 0.9.2

* Add detection of `FaceContour`s when using the `FaceDetector`. See `README.md` for more information.

## 0.9.1+1

* Update google-services Android gradle plugin to 4.3.0 in documentation and examples.

## 0.9.1

* Add support for cloud text recognizer.

## 0.9.0+3

* Automatically use version from pubspec.yaml when reporting usage to Firebase.

## 0.9.0+2

* Fix bug causing memory leak with iOS images.

## 0.9.0+1

* Update example app Podfile to match latest Flutter template and support new Xcode build system.

## 0.9.0

* **Breaking Change** Add capability to release resources held by detectors with `close()` method.
You should now call `detector.close()` when a detector will no longer be used.

## 0.8.0+3

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.8.0+2

* Fix crash when passing contact info from barcode.

## 0.8.0+1

* Update the sample to use the new ImageStreamListener API introduced in https://github.com/flutter/flutter/pull/32936.

## 0.8.0

* Update Android dependencies to latest.

## 0.7.0+2

* Fix analyzer warnings about `const Rect` in tests.

## 0.7.0+1

* Update README to match latest version.

## 0.7.0

* **Breaking Change** Unified and enhanced on-device and cloud image-labeling API.
  `iOS` now requires minimum deployment target of 9.0. Add `platform :ios, '9.0'` in your `Podfile`.
  Updated to latest version of `Firebase/MLVision` on `iOS`. Please run `pod update` in directory containing your `iOS` project `Podfile`.
  `Label` renamed to `ImageLabel`.
  `LabelDetector` renamed to `ImageLabeler`.
  Removed `CloudLabelDetector` and replaced it with a cloud `ImageLabeler`.

## 0.6.0+2

* Update README.md
* Fix crash when receiving barcode urls on iOS.

## 0.6.0+1

* Log messages about automatic configuration of the default app are now less confusing.

## 0.6.0

* **Breaking Change** Removed on-device model dependencies from plugin.
  `Android` now requires adding the on-device label detector dependency manually.
  `iOS` now requires adding the on-device barcode/face/label/text detector dependencies manually.
  See the `README.md` for more details. https://pub.dartlang.org/packages/firebase_ml_vision#-readme-tab-

## 0.5.1+2

* Fixes bug where image file needs to be rotated.

## 0.5.1+1

* Remove categories.

## 0.5.1

* iOS now handles non-planar buffers from `FirebaseVisionImage.fromBytes()`.

## 0.5.0+1

* Fixes `FIRAnalyticsVersionMismatch` compilation error on iOS. Please run `pod update` in directory
  containing `Podfile`.

## 0.5.0

* **Breaking Change** Change `Rectangle<int>` to `Rect` in Text/Face/Barcode results.
* **Breaking Change** Change `Point<int>`/`Point<double>` to `Offset` in Text/Face/Barcode results.

* Fixed bug where there were no corner points for `VisionText` or `Barcode` on iOS.

## 0.4.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.4.0

* **Breaking Change** Removal of base detector class `FirebaseVisionDetector`.
* **Breaking Change** Removal of `TextRecognizer.detectInImage()`. Please use
  `TextRecognizer.processImage()`.
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
