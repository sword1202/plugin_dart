## 3.0.5
* Removed automatic print statements for `StorageTaskEvent`'s.
  If you want to see the event status in your logs now, you will have to use the following:
  `storageReference.put{File/Data}(..).events.listen((event) => print('EVENT ${event.type}'));`
* Updated `README.md` to explain the above.

## 3.0.4

* Update google-services Android gradle plugin to 4.3.0 in documentation and examples.

## 3.0.3

* Fix inconsistency of `getPath`, on Android the path returned started with a `/` but on iOS it did not
* Fix content-type auto-detection on Android

## 3.0.2

* Automatically use version from pubspec.yaml when reporting usage to Firebase.

## 3.0.1

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 3.0.0

* Update Android dependencies to latest.

## 2.1.1+2

* On iOS, use `putFile` instead of `putData` appropriately to detect `Content-Type`.

## 2.1.1+1

* On iOS, gracefully handle the case of uploading a nonexistent file without crashing.

## 2.1.1

* Added integration tests.

## 2.1.0+1

* Reverting error.code casting/formatting to what it was until version 2.0.1.

## 2.1.0

* Added support for getReferenceFromUrl.

## 2.0.1+2

* Log messages about automatic configuration of the default app are now less confusing.

## 2.0.1+1

* Remove categories.

## 2.0.1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 2.0.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

  This was originally incorrectly pushed in the `1.1.0` update.

## 1.1.0+1

* **Revert the breaking 1.1.0 update**. 1.1.0 was known to be breaking and
  should have incremented the major version number instead of the minor. This
  revert is in and of itself breaking for anyone that has already migrated
  however. Anyone who has already migrated their app to AndroidX should
  immediately update to `2.0.0` instead. That's the correctly versioned new push
  of `1.1.0`.

## 1.1.0

* **BAD**. This was a breaking change that was incorrectly published on a minor
  version upgrade, should never have happened. Reverted by 1.1.0+1.

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 1.0.4

* Bump Android dependencies to latest.

## 1.0.3

* Added monitoring of StorageUploadTask via `events` stream.
* Added support for StorageUploadTask functions: `pause`, `resume`, `cancel`.
* Set http version to be compatible with flutter_test.

## 1.0.2

* Added missing http package dependency.

## 1.0.1

* Bump Android and Firebase dependency versions.

## 1.0.0

* **Breaking change**. Make StorageUploadTask implementation classes private.
* Bump to released version

## 0.3.7

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.3.6

* Added support for custom metadata.

## 0.3.5

* Updated iOS implementation to reflect Firebase API changes.

## 0.3.4

* Added timeout properties to FirebaseStorage.

## 0.3.3

* Added support for initialization with a custom Firebase app.

## 0.3.2

* Added support for StorageReference `writeToFile`.

## 0.3.1

* Added support for StorageReference functions: `getParent`, `getRoot`, `getStorage`, `getName`, `getPath`, `getBucket`.

## 0.3.0

* **Breaking change**. Changed StorageUploadTask to abstract, removed the 'file' field, and made 'path' and 'metadata'
  private. Added two subclasses: StorageFileUploadTask and StorageDataUploadTask.
* Deprecated the `put` function and added `putFile` and `putData` to upload files and bytes respectively.

## 0.2.6

* Added support for updateMetadata.

## 0.2.5

* Added StorageMetadata class, support for getMetadata, and support for uploading file with metadata.

## 0.2.4

* Updated Google Play Services dependencies to version 15.0.0.

## 0.2.3

* Updated package channel name and made channel visible for testing

## 0.2.2

* Simplified podspec for Cocoapods 1.5.0, avoiding link issues in app archives.

## 0.2.1

* Added support for getDownloadUrl.

## 0.2.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.1.5

* Fix Dart 2 type errors.

## 0.1.4

* Enabled use in Swift projects.

## 0.1.3

* Added StorageReference `path` getter to retrieve the path component for the storage node.

## 0.1.2

* Added StorageReference delete function to remove files from Firebase.

## 0.1.1

* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 0.1.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).
* Relaxed GMS dependency to [11.4.0,12.0[

## 0.0.8

* Added FLT prefix to iOS types
* Change GMS dependency to 11.4.+

## 0.0.7

* Change GMS dependency to 11.+

## 0.0.6

* Added StorageReference getData function to download files into memory.

## 0.0.5+1

* Aligned author name with rest of repo.

## 0.0.5

* Updated to Firebase SDK to always use latest patch version for 11.0.x builds
* Fix crash when encountering upload failure

## 0.0.4

* Updated to Firebase SDK Version 11.0.1

## 0.0.3

* Suppress unchecked warnings

## 0.0.2

* Bumped buildToolsVersion to 25.0.3
* Updated README

## 0.0.1

* Initial Release
