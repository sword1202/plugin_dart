## 2.3.0

* Switches the default for `useAndroidViewSurface` to true, and adds
  information about the current mode behaviors to the README.
* Updates minimum Flutter version to 2.10.

## 2.2.0

* Updates `useAndroidViewSurface` to require Hybrid Composition, making the
  selection work again in Flutter 3.0+. Earlier versions of Flutter are
  no longer supported.
* Fixes violations of new analysis option use_named_constants.
* Fixes avoid_redundant_argument_values lint warnings and minor typos.

## 2.1.10

* Splits Android implementation out of `google_maps_flutter` as a federated
  implementation.
