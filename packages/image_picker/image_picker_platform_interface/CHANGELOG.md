## 2.2.0

* Added new methods that return `XFile` (from `package:cross_file`)
  * `getImage` (will deprecate `pickImage`)
  * `getVideo` (will deprecate `pickVideo`)
  * `getMultiImage` (will deprecate `pickMultiImage`)

_`PickedFile` will also be marked as deprecated in an upcoming release._

## 2.1.0

* Add `pickMultiImage` method.

## 2.0.1

* Update platform_plugin_interface version requirement.

## 2.0.0

* Migrate to null safety.
* Breaking Changes:
    * Removed the deprecated methods: `ImagePickerPlatform.retrieveLostDataAsDartIoFile`,`ImagePickerPlatform.pickImagePath` and `ImagePickerPlatform.pickVideoPath`.
    * Removed deprecated class: `LostDataResponse`.

## 1.1.6

* Fix test asset file location.

## 1.1.5

* Update Flutter SDK constraint.

## 1.1.4

* Pass `Uri`s to `package:http` methods, instead of strings, in preparation for a major version update in `http`.

## 1.1.3

* Update documentation of `pickImage()` regarding HEIC images.

## 1.1.2

* Update documentation of `pickImage()` regarding compression support for specific image types.

## 1.1.1

* Update documentation of getImage() about Android's disability to preference front/rear camera.

## 1.1.0

* Introduce PickedFile type for the new API.

## 1.0.1

* Update lower bound of dart dependency to 2.1.0.

## 1.0.0

* Initial release.
