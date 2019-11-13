// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/src/in_app_purchase/purchase_details.dart';
import '../../billing_client_wrappers.dart';
import 'in_app_purchase_connection.dart';
import 'product_details.dart';

/// An [InAppPurchaseConnection] that wraps Google Play Billing.
///
/// This translates various [BillingClient] calls and responses into the
/// common plugin API.
class GooglePlayConnection
    with WidgetsBindingObserver
    implements InAppPurchaseConnection {
  GooglePlayConnection._()
      : billingClient =
            BillingClient((PurchasesResultWrapper resultWrapper) async {
          _purchaseUpdatedController
              .add(await _getPurchaseDetailsFromResult(resultWrapper));
        }) {
    _readyFuture = _connect();
    WidgetsBinding.instance.addObserver(this);
    _purchaseUpdatedController = StreamController.broadcast();
    ;
  }
  static GooglePlayConnection get instance => _getOrCreateInstance();
  static GooglePlayConnection _instance;

  Stream<List<PurchaseDetails>> get purchaseUpdatedStream =>
      _purchaseUpdatedController.stream;
  static StreamController<List<PurchaseDetails>> _purchaseUpdatedController;

  @visibleForTesting
  final BillingClient billingClient;

  Future<void> _readyFuture;
  static Set<String> _productIdsToConsume = Set<String>();

  @override
  Future<bool> isAvailable() async {
    await _readyFuture;
    return billingClient.isReady();
  }

  @override
  Future<bool> buyNonConsumable({@required PurchaseParam purchaseParam}) async {
    BillingResponse response = await billingClient.launchBillingFlow(
        sku: purchaseParam.productDetails.id,
        accountId: purchaseParam.applicationUserName);
    return response == BillingResponse.ok;
  }

  @override
  Future<bool> buyConsumable(
      {@required PurchaseParam purchaseParam, bool autoConsume = true}) {
    if (autoConsume) {
      _productIdsToConsume.add(purchaseParam.productDetails.id);
    }
    return buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    throw UnsupportedError('complete purchase is not available on Android');
  }

  @override
  Future<BillingResponse> consumePurchase(PurchaseDetails purchase) {
    return billingClient
        .consumeAsync(purchase.verificationData.serverVerificationData);
  }

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases(
      {String applicationUserName}) async {
    List<PurchasesResultWrapper> responses;
    PlatformException exception;
    try {
      responses = await Future.wait([
        billingClient.queryPurchases(SkuType.inapp),
        billingClient.queryPurchases(SkuType.subs)
      ]);
    } on PlatformException catch (e) {
      exception = e;
      responses = [
        PurchasesResultWrapper(
            responseCode: BillingResponse.error, purchasesList: []),
        PurchasesResultWrapper(
            responseCode: BillingResponse.error, purchasesList: [])
      ];
    }

    Set errorCodeSet = responses
        .where((PurchasesResultWrapper response) =>
            response.responseCode != BillingResponse.ok)
        .map((PurchasesResultWrapper response) =>
            response.responseCode.toString())
        .toSet();

    String errorMessage =
        errorCodeSet.isNotEmpty ? errorCodeSet.join(', ') : null;

    List<PurchaseDetails> pastPurchases =
        responses.expand((PurchasesResultWrapper response) {
      return response.purchasesList;
    }).map((PurchaseWrapper purchaseWrapper) {
      return PurchaseDetails.fromPurchase(purchaseWrapper);
    }).toList();

    IAPError error;
    if (exception != null) {
      error = IAPError(
          source: IAPSource.GooglePlay,
          code: exception.code,
          message: exception.message,
          details: exception.details);
    } else if (errorMessage != null) {
      error = IAPError(
          source: IAPSource.GooglePlay,
          code: kRestoredPurchaseErrorCode,
          message: errorMessage);
    }

    return QueryPurchaseDetailsResponse(
        pastPurchases: pastPurchases, error: error);
  }

  @override
  Future<PurchaseVerificationData> refreshPurchaseVerificationData() async {
    throw UnsupportedError(
        'The method <refreshPurchaseVerificationData> only works on iOS.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _disconnect();
        break;
      case AppLifecycleState.resumed:
        _readyFuture = _connect();
        break;
      default:
    }
  }

  @visibleForTesting
  static void reset() => _instance = null;

  static GooglePlayConnection _getOrCreateInstance() {
    if (_instance != null) {
      return _instance;
    }

    _instance = GooglePlayConnection._();
    return _instance;
  }

  Future<void> _connect() =>
      billingClient.startConnection(onBillingServiceDisconnected: () {});

  Future<void> _disconnect() => billingClient.endConnection();

  /// Query the product detail list.
  ///
  /// This method only returns [ProductDetailsResponse].
  /// To get detailed Google Play sku list, use [BillingClient.querySkuDetails]
  /// to get the [SkuDetailsResponseWrapper].
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    List<SkuDetailsResponseWrapper> responses;
    PlatformException exception;
    try {
      responses = await Future.wait([
        billingClient.querySkuDetails(
            skuType: SkuType.inapp, skusList: identifiers.toList()),
        billingClient.querySkuDetails(
            skuType: SkuType.subs, skusList: identifiers.toList())
      ]);
    } on PlatformException catch (e) {
      exception = e;
      responses = [
        // ignore: invalid_use_of_visible_for_testing_member
        SkuDetailsResponseWrapper(
            responseCode: BillingResponse.error, skuDetailsList: []),
        // ignore: invalid_use_of_visible_for_testing_member
        SkuDetailsResponseWrapper(
            responseCode: BillingResponse.error, skuDetailsList: [])
      ];
    }
    List<ProductDetails> productDetailsList =
        responses.expand((SkuDetailsResponseWrapper response) {
      return response.skuDetailsList;
    }).map((SkuDetailsWrapper skuDetailWrapper) {
      return ProductDetails.fromSkuDetails(skuDetailWrapper);
    }).toList();

    Set<String> successIDS = productDetailsList
        .map((ProductDetails productDetails) => productDetails.id)
        .toSet();
    List<String> notFoundIDS = identifiers.difference(successIDS).toList();
    return ProductDetailsResponse(
        productDetails: productDetailsList,
        notFoundIDs: notFoundIDS,
        error: exception == null
            ? null
            : IAPError(
                source: IAPSource.GooglePlay,
                code: exception.code,
                message: exception.message,
                details: exception.details));
  }

  static Future<List<PurchaseDetails>> _getPurchaseDetailsFromResult(
      PurchasesResultWrapper resultWrapper) async {
    IAPError error;
    PurchaseStatus status;
    if (resultWrapper.responseCode == BillingResponse.ok) {
      error = null;
      status = PurchaseStatus.purchased;
    } else {
      error = IAPError(
        source: IAPSource.GooglePlay,
        code: kPurchaseErrorCode,
        message: resultWrapper.responseCode.toString(),
      );
      status = PurchaseStatus.error;
    }
    final List<Future<PurchaseDetails>> purchases =
        resultWrapper.purchasesList.map((PurchaseWrapper purchase) {
      return _maybeAutoConsumePurchase(PurchaseDetails.fromPurchase(purchase)
        ..status = status
        ..error = error);
    }).toList();
    if (!purchases.isEmpty) {
      return Future.wait(purchases);
    } else {
      return [
        PurchaseDetails(
            purchaseID: null,
            productID: null,
            transactionDate: null,
            verificationData: null)
          ..status = PurchaseStatus.error
          ..error = error
      ];
    }
  }

  static Future<PurchaseDetails> _maybeAutoConsumePurchase(
      PurchaseDetails purchaseDetails) async {
    if (!(purchaseDetails.status == PurchaseStatus.purchased &&
        _productIdsToConsume.contains(purchaseDetails.productID))) {
      return purchaseDetails;
    }

    final BillingResponse consumedResponse =
        await instance.consumePurchase(purchaseDetails);
    if (consumedResponse != BillingResponse.ok) {
      purchaseDetails.status = PurchaseStatus.error;
      purchaseDetails.error = IAPError(
        source: IAPSource.GooglePlay,
        code: kConsumptionFailedErrorCode,
        message: consumedResponse.toString(),
      );
    }
    _productIdsToConsume.remove(purchaseDetails.productID);

    return purchaseDetails;
  }
}
