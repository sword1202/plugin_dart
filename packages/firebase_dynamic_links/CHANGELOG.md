## 0.5.0

* **Breaking change**. Changed architecture and method names to be able to differentiate between
the dynamic link which opened the app and links clicked during app execution (active and background).
`retrieveDynamicLink` has been replaced with two different functions:
- `getInitialLink` a future to retrieve the link that opened the app
- `onLink` a callback to listen to links opened while the app is active or in background

## 0.4.0+6

* Update google-services Android gradle plugin to 4.3.0 in documentation and examples.

## 0.4.0+5

* Fix the bug below properly by allowing the activity to be null (but still registering the plugin). If activity is null, we don't get a latestIntent, instead we expect the intent listener to grab it.

## 0.4.0+4

* Fixed bug on Android when a headless plugin tries to register this plugin causing a crash due no activity from the registrar.

## 0.4.0+3

* Automatically use version from pubspec.yaml when reporting usage to Firebase.

## 0.4.0+2

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.4.0+1

* Fixed bug where link persists after starting an app with a Dynamic Link.
* Fixed bug where retrieving a link would fail when app was already running.

## 0.4.0

* Update dependency on firebase_core to 0.4.0.

## 0.3.0.

* Update Android dependencies to 16.1.7.
* **Breaking change**. Dynamic link parameter `domain` replaced with `uriPrefix`.

## 0.2.1

* Throw `PlatformException` if there is an error retrieving dynamic link.

## 0.2.0+4

* Fix crash when receiving `ShortDynamicLink` warnings.

## 0.2.0+3

* Log messages about automatic configuration of the default app are now less confusing.

## 0.2.0+2

* Remove categories.

## 0.2.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.2.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.1.1

* Update example to create a clickable and copyable link.

## 0.1.0+2

* Change android `invites` dependency to `dynamic links` dependency.

## 0.1.0+1

* Bump Android dependencies to latest.

## 0.1.0

* **Breaking Change** Calls to retrieve dynamic links on iOS always returns null after first call.

## 0.0.6

* Bump Android and Firebase dependency versions.

## 0.0.5

* Added capability to receive dynamic links.

## 0.0.4

* Fixed dynamic link dartdoc generation.

## 0.0.3

* Fixed incorrect homepage link in pubspec.

## 0.0.2

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.0.1

* Initial release with api to create long or short dynamic links.
