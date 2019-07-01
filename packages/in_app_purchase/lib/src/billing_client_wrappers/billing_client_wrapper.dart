// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../channel.dart';
import 'purchase_wrapper.dart';
import 'sku_details_wrapper.dart';
import 'enum_converters.dart';

@visibleForTesting
const String kOnPurchasesUpdated =
    'PurchasesUpdatedListener#onPurchasesUpdated(int, List<Purchase>)';
const String _kOnBillingServiceDisconnected =
    'BillingClientStateListener#onBillingServiceDisconnected()';

/// Callback triggered by Play in response to purchase activity.
///
/// This callback is triggered in response to all purchase activity while an
/// instance of `BillingClient` is active. This includes purchases initiated by
/// the app ([BillingClient.launchBillingFlow]) as well as purchases made in
/// Play itself while this app is open.
///
/// This does not provide any hooks for purchases made in the past. See
/// [BillingClient.queryPurchases] and [BillingClient.queryPurchaseHistory].
///
/// All purchase information should also be verified manually, with your server
/// if at all possible. See ["Verify a
/// purchase"](https://developer.android.com/google/play/billing/billing_library_overview#Verify).
///
/// Wraps a
/// [`PurchasesUpdatedListener`](https://developer.android.com/reference/com/android/billingclient/api/PurchasesUpdatedListener.html).
typedef void PurchasesUpdatedListener(PurchasesResultWrapper purchasesResult);

/// This class can be used directly instead of [InAppPurchaseConnection] to call
/// Play-specific billing APIs.
///
/// Wraps a
/// [`com.android.billingclient.api.BillingClient`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient)
/// instance.
///
///
/// In general this API conforms to the Java
/// `com.android.billingclient.api.BillingClient` API as much as possible, with
/// some minor changes to account for language differences. Callbacks have been
/// converted to futures where appropriate.
class BillingClient {
  BillingClient(PurchasesUpdatedListener onPurchasesUpdated) {
    assert(onPurchasesUpdated != null);
    channel.setMethodCallHandler(callHandler);
    _callbacks[kOnPurchasesUpdated] = [onPurchasesUpdated];
  }

  // Occasionally methods in the native layer require a Dart callback to be
  // triggered in response to a Java callback. For example,
  // [startConnection] registers an [OnBillingServiceDisconnected] callback.
  // This list of names to callbacks is used to trigger Dart callbacks in
  // response to those Java callbacks. Dart sends the Java layer a handle to the
  // matching callback here to remember, and then once its twin is triggered it
  // sends the handle back over the platform channel. We then access that handle
  // in this array and call it in Dart code. See also [_callHandler].
  Map<String, List<Function>> _callbacks = <String, List<Function>>{};

  /// Calls
  /// [`BillingClient#isReady()`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.html#isReady())
  /// to get the ready status of the BillingClient instance.
  Future<bool> isReady() async =>
      await channel.invokeMethod<bool>('BillingClient#isReady()');

  /// Calls
  /// [`BillingClient#startConnection(BillingClientStateListener)`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.html#startconnection)
  /// to create and connect a `BillingClient` instance.
  ///
  /// [onBillingServiceConnected] has been converted from a callback parameter
  /// to the Future result returned by this function. This returns the
  /// `BillingClient.BillingResponse` `responseCode` of the connection result.
  ///
  /// This triggers the creation of a new `BillingClient` instance in Java if
  /// one doesn't already exist.
  Future<BillingResponse> startConnection(
      {@required
          OnBillingServiceDisconnected onBillingServiceDisconnected}) async {
    List<Function> disconnectCallbacks =
        _callbacks[_kOnBillingServiceDisconnected] ??= [];
    disconnectCallbacks.add(onBillingServiceDisconnected);
    return BillingResponseConverter().fromJson(await channel.invokeMethod<int>(
        "BillingClient#startConnection(BillingClientStateListener)",
        <String, dynamic>{'handle': disconnectCallbacks.length - 1}));
  }

  /// Calls
  /// [`BillingClient#endConnection(BillingClientStateListener)`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.html#endconnect
  /// to disconnect a `BillingClient` instance.
  ///
  /// Will trigger the [OnBillingServiceDisconnected] callback passed to [startConnection].
  ///
  /// This triggers the destruction of the `BillingClient` instance in Java.
  Future<void> endConnection() async {
    return channel.invokeMethod<void>("BillingClient#endConnection()", null);
  }

  /// Returns a list of [SkuDetailsWrapper]s that have [SkuDetailsWrapper.sku]
  /// in `skusList`, and [SkuDetailsWrapper.type] matching `skuType`.
  ///
  /// Calls through to [`BillingClient#querySkuDetailsAsync(SkuDetailsParams,
  /// SkuDetailsResponseListener)`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient#querySkuDetailsAsync(com.android.billingclient.api.SkuDetailsParams,%20com.android.billingclient.api.SkuDetailsResponseListener))
  /// Instead of taking a callback parameter, it returns a Future
  /// [SkuDetailsResponseWrapper]. It also takes the values of
  /// `SkuDetailsParams` as direct arguments instead of requiring it constructed
  /// and passed in as a class.
  Future<SkuDetailsResponseWrapper> querySkuDetails(
      {@required SkuType skuType, @required List<String> skusList}) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      'skuType': SkuTypeConverter().toJson(skuType),
      'skusList': skusList
    };
    return SkuDetailsResponseWrapper.fromJson(await channel.invokeMapMethod<
            String, dynamic>(
        'BillingClient#querySkuDetailsAsync(SkuDetailsParams, SkuDetailsResponseListener)',
        arguments));
  }

  /// Attempt to launch the Play Billing Flow for a given [skuDetails].
  ///
  /// The [skuDetails] needs to have already been fetched in a [querySkuDetails]
  /// call. The [accountId] is an optional hashed string associated with the user
  /// that's unique to your app. It's used by Google to detect unusual behavior.
  /// Do not pass in a cleartext [accountId], use your developer ID, or use the
  /// user's Google ID for this field.
  ///
  /// Calling this attemps to show the Google Play purchase UI. The user is free
  /// to complete the transaction there.
  ///
  /// This method returns a [BillingResponse] representing the initial attempt
  /// to show the Google Play billing flow. Actual purchase updates are
  /// delivered via the [PurchasesUpdatedListener].
  ///
  /// This method calls through to
  /// [`BillingClient#launchBillingFlow`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient#launchbillingflow).
  /// It constructs a
  /// [`BillingFlowParams`](https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams)
  /// instance by [setting the given
  /// skuDetails](https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.Builder.html#setskudetails)
  /// and [the given
  /// accountId](https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.Builder.html#setAccountId(java.lang.String)).
  Future<BillingResponse> launchBillingFlow(
      {@required String sku, String accountId}) async {
    assert(sku != null);
    final Map<String, dynamic> arguments = <String, dynamic>{
      'sku': sku,
      'accountId': accountId,
    };
    return BillingResponseConverter().fromJson(await channel.invokeMethod<int>(
        'BillingClient#launchBillingFlow(Activity, BillingFlowParams)',
        arguments));
  }

  /// Fetches recent purchases for the given [SkuType].
  ///
  /// Unlike [queryPurchaseHistory], This does not make a network request and
  /// does not return items that are no longer owned.
  ///
  /// All purchase information should also be verified manually, with your
  /// server if at all possible. See ["Verify a
  /// purchase"](https://developer.android.com/google/play/billing/billing_library_overview#Verify).
  ///
  /// This wraps [`BillingClient#queryPurchases(String
  /// skutype)`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient#querypurchases).
  Future<PurchasesResultWrapper> queryPurchases(SkuType skuType) async {
    assert(skuType != null);
    return PurchasesResultWrapper.fromJson(await channel
        .invokeMapMethod<String, dynamic>(
            'BillingClient#queryPurchases(String)',
            <String, dynamic>{'skuType': SkuTypeConverter().toJson(skuType)}));
  }

  /// Fetches purchase history for the given [SkuType].
  ///
  /// Unlike [queryPurchases], this makes a network request via Play and returns
  /// the most recent purchase for each [SkuDetailsWrapper] of the given
  /// [SkuType] even if the item is no longer owned.
  ///
  /// All purchase information should also be verified manually, with your
  /// server if at all possible. See ["Verify a
  /// purchase"](https://developer.android.com/google/play/billing/billing_library_overview#Verify).
  ///
  /// This wraps [`BillingClient#queryPurchaseHistoryAsync(String skuType,
  /// PurchaseHistoryResponseListener
  /// listener)`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient#querypurchasehistoryasync).
  Future<PurchasesResultWrapper> queryPurchaseHistory(SkuType skuType) async {
    assert(skuType != null);
    return PurchasesResultWrapper.fromJson(await channel
        .invokeMapMethod<String, dynamic>(
            'BillingClient#queryPurchaseHistoryAsync(String, PurchaseHistoryResponseListener)',
            <String, dynamic>{'skuType': SkuTypeConverter().toJson(skuType)}));
  }

  /// Consumes a given in-app product.
  ///
  /// Consuming can only be done on an item that's owned, and as a result of consumption, the user will no longer own it.
  /// Consumption is done asynchronously. The method returns a Future containing a [BillingResponse].
  ///
  /// This wraps [`BillingClient#consumeAsync(String, ConsumeResponseListener)`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.html#consumeAsync(java.lang.String,%20com.android.billingclient.api.ConsumeResponseListener))
  Future<BillingResponse> consumeAsync(String purchaseToken) async {
    assert(purchaseToken != null);
    return BillingResponseConverter().fromJson(await channel.invokeMethod<int>(
      'BillingClient#consumeAsync(String, ConsumeResponseListener)',
      <String, String>{'purchaseToken': purchaseToken},
    ));
  }

  @visibleForTesting
  Future<void> callHandler(MethodCall call) async {
    switch (call.method) {
      case kOnPurchasesUpdated:
        // The purchases updated listener is a singleton.
        assert(_callbacks[kOnPurchasesUpdated].length == 1);
        final PurchasesUpdatedListener listener =
            _callbacks[kOnPurchasesUpdated].first;
        listener(PurchasesResultWrapper.fromJson(
            call.arguments.cast<String, dynamic>()));
        break;
      case _kOnBillingServiceDisconnected:
        final int handle = call.arguments['handle'];
        await _callbacks[_kOnBillingServiceDisconnected][handle]();
        break;
    }
  }
}

/// Callback triggered when the [BillingClientWrapper] is disconnected.
///
/// Wraps
/// [`com.android.billingclient.api.BillingClientStateListener.onServiceDisconnected()`](https://developer.android.com/reference/com/android/billingclient/api/BillingClientStateListener.html#onBillingServiceDisconnected())
/// to call back on `BillingClient` disconnect.
typedef void OnBillingServiceDisconnected();

/// Possible `BillingClient` response statuses.
///
/// Wraps
/// [`BillingClient.BillingResponse`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.BillingResponse).
/// See the `BillingResponse` docs for more explanation of the different
/// constants.
enum BillingResponse {
  // WARNING: Changes to this class need to be reflected in our generated code.
  // Run `flutter packages pub run build_runner watch` to rebuild and watch for
  // further changes.
  @JsonValue(-2)
  featureNotSupported,

  @JsonValue(-1)
  serviceDisconnected,

  @JsonValue(0)
  ok,

  @JsonValue(1)
  userCanceled,

  @JsonValue(2)
  serviceUnavailable,

  @JsonValue(3)
  billingUnavailable,

  @JsonValue(4)
  itemUnavailable,

  @JsonValue(5)
  developerError,

  @JsonValue(6)
  error,

  @JsonValue(7)
  itemAlreadyOwned,

  @JsonValue(8)
  itemNotOwned,
}

/// Enum representing potential [SkuDetailsWrapper.type]s.
///
/// Wraps
/// [`BillingClient.SkuType`](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.SkuType)
/// See the linked documentation for an explanation of the different constants.
enum SkuType {
  // WARNING: Changes to this class need to be reflected in our generated code.
  // Run `flutter packages pub run build_runner watch` to rebuild and watch for
  // further changes.

  /// A one time product. Acquired in a single transaction.
  @JsonValue('inapp')
  inapp,

  /// A product requiring a recurring charge over time.
  @JsonValue('subs')
  subs,
}
