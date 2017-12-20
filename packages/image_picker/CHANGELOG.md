## 0.2.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.1.5

* Added FLT prefix to iOS types

## 0.1.4

* Bugfix: canceling image picking threw exception.
* Bugfix: errors in plugin state management.

## 0.1.3

* Added optional source argument to pickImage for controlling where the image comes from.

## 0.1.2

* Added optional maxWidth and maxHeight arguments to pickImage.

## 0.1.1

* Updated Gradle repositories declaration to avoid the need for manual configuration
  in the consuming app.

## 0.1.0+1

* Updated readme and description in pubspec.yaml

## 0.1.0

* Updated dependencies
* **Breaking Change**: You need to add a maven section with the "https://maven.google.com" endpoint to the repository section of your `android/build.gradle`. For example:
```gradle
allprojects {
    repositories {
        jcenter()
        maven {                              // NEW
            url "https://maven.google.com"   // NEW
        }                                    // NEW
    }
}
```

## 0.0.3

* Fix for crash on iPad when showing the Camera/Gallery selection dialog

## 0.0.2+2

* Updated README

## 0.0.2+1

* Updated README

## 0.0.2

* Fix crash when trying to access camera on a device without camera (e.g. the Simulator)

## 0.0.1

* Initial Release
