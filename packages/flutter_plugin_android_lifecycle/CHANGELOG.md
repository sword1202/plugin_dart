## 1.0.4

* Require Flutter SDK 1.12.13 or greater.
* Change to avoid reflection.

## 1.0.3

* Remove the deprecated `author:` field from pubspec.yaml
* Require Flutter SDK 1.10.0 or greater.

## 1.0.2

* Adapt to the embedding API changes in https://github.com/flutter/engine/pull/13280 (only supports Activity Lifecycle).

## 1.0.1
* Register the E2E plugin in the example app.

## 1.0.0

* Introduces a `FlutterLifecycleAdapter`, which can be used by other plugins to obtain a `Lifecycle`
  reference from a `FlutterPluginBinding`.
