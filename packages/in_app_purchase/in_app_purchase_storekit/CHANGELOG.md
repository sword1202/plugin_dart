## 0.3.0

* **BREAKING CHANGE:** `InAppPurchaseStoreKitPlatform.restorePurchase()` emits an empty instance of `List<ProductDetails>` when there were no transactions to restore, indicating that the restore procedure has finished. 

## 0.2.1

* Renames `in_app_purchase_ios` to `in_app_purchase_storekit` to facilitate
  future macOS support.
