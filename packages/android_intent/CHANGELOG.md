##  0.3.4+8

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

##  0.3.4+7

* Fix pedantic linter errors.

##  0.3.4+6

* Add missing DartDocs for public members.

##  0.3.4+5

* Remove AndroidX warning.

## 0.3.4+4

* Include lifecycle dependency as a compileOnly one on Android to resolve
  potential version conflicts with other transitive libraries.

## 0.3.4+3

* Android: Use android.arch.lifecycle instead of androidx.lifecycle:lifecycle in `build.gradle` to support apps that has not been migrated to AndroidX.

## 0.3.4+2

* Fix resolveActivity not respecting the provided componentName.

## 0.3.4+1

* Fix minor lints in the Java platform code.
* Add smoke e2e tests for the V2 embedding.
* Fully migrate the example app to AndroidX.

## 0.3.4

* Migrate the plugin to use the V2 Android engine embedding. This shouldn't
  affect existing functionality. Plugin authors who use the V2 embedding can now
  instantiate the plugin and expect that it correctly responds to app lifecycle
  changes.

## 0.3.3+3

* Define clang module for iOS.

## 0.3.3+2

* Update and migrate iOS example project.

## 0.3.3+1

* Added "action_application_details_settings" action to open application info settings .

## 0.3.3

* Added "flags" option to call intent.addFlags(int) in native.

## 0.3.2

* Added "action_location_source_settings" action to start Location Settings Activity.

## 0.3.1+1

* Fix Gradle version.

## 0.3.1

* Add a new componentName parameter to help the intent resolution.

## 0.3.0+2

* Bump the minimum Flutter version to 1.2.0.
* Add template type parameter to `invokeMethod` calls.

## 0.3.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.3.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.2.1

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.2.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.1.1

* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 0.1.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.0.3

* Add FLT prefix to iOS types.

## 0.0.2

* Add support for transferring structured Dart values into Android Intent
  instances as extra Bundle data.

## 0.0.1

* Initial release
