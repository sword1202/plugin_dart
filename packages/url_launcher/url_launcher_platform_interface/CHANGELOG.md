## 1.0.4

* Use the common PlatformInterface code from plugin_platform_interface.
* [TEST ONLY BREAKING CHANGE] remove UrlLauncherPlatform.isMock, we're not increasing the major version
  as doing so for platform interfaces has bad implications, given that this is only going to break
  test code, and that the plugin is young and shouldn't have third-party users we've decided to land
  this as a patch bump.

## 1.0.3

* Minor DartDoc changes and add a lint for missing DartDocs.

## 1.0.2

* Use package URI in test directory to import code from lib.

## 1.0.1

* Enforce that UrlLauncherPlatform isn't implemented with `implements`.

## 1.0.0

* Initial release.
