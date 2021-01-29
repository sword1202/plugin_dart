# 0.1.5+3

- Fix Link misalignment [issue](https://github.com/flutter/flutter/issues/70053).

# 0.1.5+2

- Update Flutter SDK constraint.

# 0.1.5+1

- Substitute `undefined_prefixed_name: ignore` analyzer setting by a `dart:ui` shim with conditional exports. [Issue](https://github.com/flutter/flutter/issues/69309).

# 0.1.5

- Added the web implementation of the Link widget.

# 0.1.4+2

- Move `lib/third_party` to `lib/src/third_party`.

# 0.1.4+1

- Add a more correct attribution to `package:platform_detect` code.

# 0.1.4

- (Null safety) Remove dependency on `package:platform_detect`
- Port unit tests to run with `flutter drive`

# 0.1.3+2

- Fix a typo in a test name and fix some style inconsistencies.

# 0.1.3+1

- Depend explicitly on the `platform_interface` package that adds the `webOnlyWindowName` parameter.

# 0.1.3

- Added webOnlyWindowName parameter to launch()

# 0.1.2+1

- Update docs

# 0.1.2

- Adds "tel" and "sms" support

# 0.1.1+6

- Open "mailto" urls with target set as "\_top" on Safari browsers.
- Update lower bound of dart dependency to 2.2.0.

# 0.1.1+5

- Update lower bound of dart dependency to 2.1.0.

# 0.1.1+4

- Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

# 0.1.1+3

- Refactor tests to not rely on the underlying browser behavior.

# 0.1.1+2

- Open urls with target "\_top" on iOS PWAs.

# 0.1.1+1

- Make the pedantic dev_dependency explicit.

# 0.1.1

- Added support for mailto scheme

# 0.1.0+2

- Remove androidx references from the no-op android implemenation.

# 0.1.0+1

- Add an android/ folder with no-op implementation to workaround https://github.com/flutter/flutter/issues/46304.
- Bump the minimal required Flutter version to 1.10.0.

# 0.1.0

- Update docs and pubspec.

# 0.0.2

- Switch to using `url_launcher_platform_interface`.

# 0.0.1

- Initial open-source release.
