// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:in_app_purchase/src/in_app_purchase/purchase_details.dart';
import 'package:test/test.dart';

import 'package:flutter/widgets.dart' hide TypeMatcher;
import 'package:in_app_purchase/billing_client_wrappers.dart';
import 'package:in_app_purchase/src/billing_client_wrappers/enum_converters.dart';
import 'package:in_app_purchase/src/in_app_purchase/google_play_connection.dart';
import 'package:in_app_purchase/src/in_app_purchase/in_app_purchase_connection.dart';
import 'package:in_app_purchase/src/channel.dart';
import '../stub_in_app_purchase_platform.dart';
import 'package:in_app_purchase/src/in_app_purchase/product_details.dart';
import '../billing_client_wrappers/sku_details_wrapper_test.dart';
import '../billing_client_wrappers/purchase_wrapper_test.dart';

void main() {
  final StubInAppPurchasePlatform stubPlatform = StubInAppPurchasePlatform();
  GooglePlayConnection connection;
  const String startConnectionCall =
      'BillingClient#startConnection(BillingClientStateListener)';
  const String endConnectionCall = 'BillingClient#endConnection()';

  setUpAll(() {
    channel.setMockMethodCallHandler(stubPlatform.fakeMethodCallHandler);
  });

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    stubPlatform.addResponse(
        name: startConnectionCall,
        value: BillingResponseConverter().toJson(BillingResponse.ok));
    stubPlatform.addResponse(name: endConnectionCall, value: null);
    connection = GooglePlayConnection.instance;
  });

  tearDown(() {
    stubPlatform.reset();
    GooglePlayConnection.reset();
  });

  group('connection management', () {
    test('connects on initialization', () {
      expect(stubPlatform.countPreviousCalls(startConnectionCall), equals(1));
    });

    test('disconnects on app pause', () {
      expect(stubPlatform.countPreviousCalls(endConnectionCall), equals(0));
      connection.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(stubPlatform.countPreviousCalls(endConnectionCall), equals(1));
    });

    test('reconnects on app resume', () {
      expect(stubPlatform.countPreviousCalls(startConnectionCall), equals(1));
      connection.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(stubPlatform.countPreviousCalls(startConnectionCall), equals(2));
    });
  });

  group('isAvailable', () {
    test('true', () async {
      stubPlatform.addResponse(name: 'BillingClient#isReady()', value: true);
      expect(await connection.isAvailable(), isTrue);
    });

    test('false', () async {
      stubPlatform.addResponse(name: 'BillingClient#isReady()', value: false);
      expect(await connection.isAvailable(), isFalse);
    });
  });

  group('querySkuDetails', () {
    final String queryMethodName =
        'BillingClient#querySkuDetailsAsync(SkuDetailsParams, SkuDetailsResponseListener)';

    test('handles empty skuDetails', () async {
      final BillingResponse responseCode = BillingResponse.developerError;
      stubPlatform.addResponse(name: queryMethodName, value: <dynamic, dynamic>{
        'responseCode': BillingResponseConverter().toJson(responseCode),
        'skuDetailsList': <Map<String, dynamic>>[]
      });

      final ProductDetailsResponse response =
          await connection.queryProductDetails(<String>[''].toSet());
      expect(response.productDetails, isEmpty);
    });

    test('should get correct product details', () async {
      final BillingResponse responseCode = BillingResponse.ok;
      stubPlatform.addResponse(name: queryMethodName, value: <String, dynamic>{
        'responseCode': BillingResponseConverter().toJson(responseCode),
        'skuDetailsList': <Map<String, dynamic>>[buildSkuMap(dummySkuDetails)]
      });
      // Since queryProductDetails makes 2 platform method calls (one for each SkuType), the result will contain 2 dummyWrapper instead
      // of 1.
      final ProductDetailsResponse response =
          await connection.queryProductDetails(<String>['valid'].toSet());
      expect(response.productDetails.first.title, dummySkuDetails.title);
      expect(response.productDetails.first.description,
          dummySkuDetails.description);
      expect(response.productDetails.first.price, dummySkuDetails.price);
    });

    test('should get the correct notFoundIDs', () async {
      final BillingResponse responseCode = BillingResponse.ok;
      stubPlatform.addResponse(name: queryMethodName, value: <String, dynamic>{
        'responseCode': BillingResponseConverter().toJson(responseCode),
        'skuDetailsList': <Map<String, dynamic>>[buildSkuMap(dummySkuDetails)]
      });
      // Since queryProductDetails makes 2 platform method calls (one for each SkuType), the result will contain 2 dummyWrapper instead
      // of 1.
      final ProductDetailsResponse response =
          await connection.queryProductDetails(<String>['invalid'].toSet());
      expect(response.notFoundIDs.first, 'invalid');
    });

    test(
        'should have error stored in the response when platform exception is thrown',
        () async {
      final BillingResponse responseCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: queryMethodName,
          value: <String, dynamic>{
            'responseCode': BillingResponseConverter().toJson(responseCode),
            'skuDetailsList': <Map<String, dynamic>>[
              buildSkuMap(dummySkuDetails)
            ]
          },
          additionalStepBeforeReturn: (_) {
            throw PlatformException(
              code: 'error_code',
              message: 'error_message',
              details: {'info': 'error_info'},
            );
          });
      // Since queryProductDetails makes 2 platform method calls (one for each SkuType), the result will contain 2 dummyWrapper instead
      // of 1.
      final ProductDetailsResponse response =
          await connection.queryProductDetails(<String>['invalid'].toSet());
      expect(response.notFoundIDs, ['invalid']);
      expect(response.productDetails, isEmpty);
      expect(response.error.source, IAPSource.GooglePlay);
      expect(response.error.code, 'error_code');
      expect(response.error.message, 'error_message');
      expect(response.error.details, {'info': 'error_info'});
    });
  });

  group('queryPurchaseDetails', () {
    const String queryMethodName = 'BillingClient#queryPurchases(String)';
    test('handles error', () async {
      final BillingResponse responseCode = BillingResponse.developerError;
      stubPlatform.addResponse(name: queryMethodName, value: <dynamic, dynamic>{
        'responseCode': BillingResponseConverter().toJson(responseCode),
        'purchasesList': <Map<String, dynamic>>[]
      });
      final QueryPurchaseDetailsResponse response =
          await connection.queryPastPurchases();
      expect(response.pastPurchases, isEmpty);
      expect(response.error.message, BillingResponse.developerError.toString());
      expect(response.error.source, IAPSource.GooglePlay);
    });

    test('returns SkuDetailsResponseWrapper', () async {
      final BillingResponse responseCode = BillingResponse.ok;
      stubPlatform.addResponse(name: queryMethodName, value: <String, dynamic>{
        'responseCode': BillingResponseConverter().toJson(responseCode),
        'purchasesList': <Map<String, dynamic>>[
          buildPurchaseMap(dummyPurchase),
        ]
      });

      // Since queryPastPurchases makes 2 platform method calls (one for each SkuType), the result will contain 2 dummyWrapper instead
      // of 1.
      final QueryPurchaseDetailsResponse response =
          await connection.queryPastPurchases();
      expect(response.error, isNull);
      expect(response.pastPurchases.first.purchaseID, dummyPurchase.orderId);
    });

    test('should store platform exception in the response', () async {
      final BillingResponse responseCode = BillingResponse.developerError;
      stubPlatform.addResponse(
          name: queryMethodName,
          value: <dynamic, dynamic>{
            'responseCode': BillingResponseConverter().toJson(responseCode),
            'purchasesList': <Map<String, dynamic>>[]
          },
          additionalStepBeforeReturn: (_) {
            throw PlatformException(
              code: 'error_code',
              message: 'error_message',
              details: {'info': 'error_info'},
            );
          });
      final QueryPurchaseDetailsResponse response =
          await connection.queryPastPurchases();
      expect(response.pastPurchases, isEmpty);
      expect(response.error.code, 'error_code');
      expect(response.error.message, 'error_message');
      expect(response.error.details, {'info': 'error_info'});
    });
  });

  group('refresh receipt data', () {
    test('should throw on android', () {
      expect(GooglePlayConnection.instance.refreshPurchaseVerificationData(),
          throwsUnsupportedError);
    });
  });

  group('make payment', () {
    final String launchMethodName =
        'BillingClient#launchBillingFlow(Activity, BillingFlowParams)';
    const String consumeMethodName =
        'BillingClient#consumeAsync(String, ConsumeResponseListener)';
    test('buy non consumable, serializes and deserializes data', () async {
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";
      final BillingResponse sentCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: launchMethodName,
          value: BillingResponseConverter().toJson(sentCode),
          additionalStepBeforeReturn: (_) {
            // Mock java update purchase callback.
            MethodCall call = MethodCall(kOnPurchasesUpdated, {
              'responseCode': BillingResponseConverter().toJson(sentCode),
              'purchasesList': [
                {
                  'orderId': 'orderID1',
                  'sku': skuDetails.sku,
                  'isAutoRenewing': false,
                  'packageName': "package",
                  'purchaseTime': 1231231231,
                  'purchaseToken': "token",
                  'signature': 'sign',
                  'originalJson': 'json'
                }
              ]
            });
            connection.billingClient.callHandler(call);
          });
      Completer completer = Completer();
      PurchaseDetails purchaseDetails;
      Stream purchaseStream =
          GooglePlayConnection.instance.purchaseUpdatedStream;
      StreamSubscription subscription;
      subscription = purchaseStream.listen((_) {
        purchaseDetails = _.first;
        completer.complete(purchaseDetails);
        subscription.cancel();
      }, onDone: () {});
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSkuDetails(skuDetails),
          applicationUserName: accountId);
      final bool launchResult = await GooglePlayConnection.instance
          .buyNonConsumable(purchaseParam: purchaseParam);

      PurchaseDetails result = await completer.future;
      expect(launchResult, isTrue);
      expect(result.purchaseID, 'orderID1');
      expect(result.status, PurchaseStatus.purchased);
      expect(result.productID, dummySkuDetails.sku);
    });

    test('handles an error with an empty purchases list', () async {
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";
      final BillingResponse sentCode = BillingResponse.error;
      stubPlatform.addResponse(
          name: launchMethodName,
          value: BillingResponseConverter().toJson(sentCode),
          additionalStepBeforeReturn: (_) {
            // Mock java update purchase callback.
            MethodCall call = MethodCall(kOnPurchasesUpdated, {
              'responseCode': BillingResponseConverter().toJson(sentCode),
              'purchasesList': []
            });
            connection.billingClient.callHandler(call);
          });
      Completer completer = Completer();
      PurchaseDetails purchaseDetails;
      Stream purchaseStream =
          GooglePlayConnection.instance.purchaseUpdatedStream;
      StreamSubscription subscription;
      subscription = purchaseStream.listen((_) {
        purchaseDetails = _.first;
        completer.complete(purchaseDetails);
        subscription.cancel();
      }, onDone: () {});
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSkuDetails(skuDetails),
          applicationUserName: accountId);
      await GooglePlayConnection.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
      PurchaseDetails result = await completer.future;

      expect(result.error, isNotNull);
      expect(result.error.source, IAPSource.GooglePlay);
      expect(result.status, PurchaseStatus.error);
      expect(result.purchaseID, isNull);
    });

    test('buy consumable with auto consume, serializes and deserializes data',
        () async {
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";
      final BillingResponse sentCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: launchMethodName,
          value: BillingResponseConverter().toJson(sentCode),
          additionalStepBeforeReturn: (_) {
            // Mock java update purchase callback.
            MethodCall call = MethodCall(kOnPurchasesUpdated, {
              'responseCode': BillingResponseConverter().toJson(sentCode),
              'purchasesList': [
                {
                  'orderId': 'orderID1',
                  'sku': skuDetails.sku,
                  'isAutoRenewing': false,
                  'packageName': "package",
                  'purchaseTime': 1231231231,
                  'purchaseToken': "token",
                  'signature': 'sign',
                  'originalJson': 'json'
                }
              ]
            });
            connection.billingClient.callHandler(call);
          });
      Completer consumeCompleter = Completer();
      // adding call back for consume purchase
      final BillingResponse expectedCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: consumeMethodName,
          value: BillingResponseConverter().toJson(expectedCode),
          additionalStepBeforeReturn: (dynamic args) {
            String purchaseToken = args['purchaseToken'];
            consumeCompleter.complete((purchaseToken));
          });

      Completer completer = Completer();
      PurchaseDetails purchaseDetails;
      Stream purchaseStream =
          GooglePlayConnection.instance.purchaseUpdatedStream;
      StreamSubscription subscription;
      subscription = purchaseStream.listen((_) {
        purchaseDetails = _.first;
        completer.complete(purchaseDetails);
        subscription.cancel();
      }, onDone: () {});
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSkuDetails(skuDetails),
          applicationUserName: accountId);
      final bool launchResult = await GooglePlayConnection.instance
          .buyConsumable(purchaseParam: purchaseParam);

      // Verify that the result has succeeded
      PurchaseDetails result = await completer.future;
      expect(launchResult, isTrue);
      expect(result.billingClientPurchase.purchaseToken,
          await consumeCompleter.future);
      expect(result.status, PurchaseStatus.purchased);
      expect(result.error, isNull);
    });

    test('buyNonConsumable propagates failures to launch the billing flow',
        () async {
      final BillingResponse sentCode = BillingResponse.error;
      stubPlatform.addResponse(
          name: launchMethodName,
          value: BillingResponseConverter().toJson(sentCode));

      final bool result = await GooglePlayConnection.instance.buyNonConsumable(
          purchaseParam: PurchaseParam(
              productDetails: ProductDetails.fromSkuDetails(dummySkuDetails)));

      // Verify that the failure has been converted and returned
      expect(result, isFalse);
    });

    test('buyConsumable propagates failures to launch the billing flow',
        () async {
      final BillingResponse sentCode = BillingResponse.error;
      stubPlatform.addResponse(
          name: launchMethodName,
          value: BillingResponseConverter().toJson(sentCode));

      final bool result = await GooglePlayConnection.instance.buyConsumable(
          purchaseParam: PurchaseParam(
              productDetails: ProductDetails.fromSkuDetails(dummySkuDetails)));

      // Verify that the failure has been converted and returned
      expect(result, isFalse);
    });

    test('adds consumption failures to PurchaseDetails objects', () async {
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";
      final BillingResponse sentCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: launchMethodName,
          value: BillingResponseConverter().toJson(sentCode),
          additionalStepBeforeReturn: (_) {
            // Mock java update purchase callback.
            MethodCall call = MethodCall(kOnPurchasesUpdated, {
              'responseCode': BillingResponseConverter().toJson(sentCode),
              'purchasesList': [
                {
                  'orderId': 'orderID1',
                  'sku': skuDetails.sku,
                  'isAutoRenewing': false,
                  'packageName': "package",
                  'purchaseTime': 1231231231,
                  'purchaseToken': "token",
                  'signature': 'sign',
                  'originalJson': 'json'
                }
              ]
            });
            connection.billingClient.callHandler(call);
          });
      Completer consumeCompleter = Completer();
      // adding call back for consume purchase
      final BillingResponse expectedCode = BillingResponse.error;
      stubPlatform.addResponse(
          name: consumeMethodName,
          value: BillingResponseConverter().toJson(expectedCode),
          additionalStepBeforeReturn: (dynamic args) {
            String purchaseToken = args['purchaseToken'];
            consumeCompleter.complete((purchaseToken));
          });

      Completer completer = Completer();
      PurchaseDetails purchaseDetails;
      Stream purchaseStream =
          GooglePlayConnection.instance.purchaseUpdatedStream;
      StreamSubscription subscription;
      subscription = purchaseStream.listen((_) {
        purchaseDetails = _.first;
        completer.complete(purchaseDetails);
        subscription.cancel();
      }, onDone: () {});
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSkuDetails(skuDetails),
          applicationUserName: accountId);
      await GooglePlayConnection.instance
          .buyConsumable(purchaseParam: purchaseParam);

      // Verify that the result has an error for the failed consumption
      PurchaseDetails result = await completer.future;
      expect(result.billingClientPurchase.purchaseToken,
          await consumeCompleter.future);
      expect(result.status, PurchaseStatus.error);
      expect(result.error, isNotNull);
      expect(result.error.code, kConsumptionFailedErrorCode);
    });

    test(
        'buy consumable without auto consume, consume api should not receive calls',
        () async {
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";
      final BillingResponse sentCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: launchMethodName,
          value: BillingResponseConverter().toJson(sentCode),
          additionalStepBeforeReturn: (_) {
            // Mock java update purchase callback.
            MethodCall call = MethodCall(kOnPurchasesUpdated, {
              'responseCode': BillingResponseConverter().toJson(sentCode),
              'purchasesList': [
                {
                  'orderId': 'orderID1',
                  'sku': skuDetails.sku,
                  'isAutoRenewing': false,
                  'packageName': "package",
                  'purchaseTime': 1231231231,
                  'purchaseToken': "token",
                  'signature': 'sign',
                  'originalJson': 'json'
                }
              ]
            });
            connection.billingClient.callHandler(call);
          });
      Completer consumeCompleter = Completer();
      // adding call back for consume purchase
      final BillingResponse expectedCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: consumeMethodName,
          value: BillingResponseConverter().toJson(expectedCode),
          additionalStepBeforeReturn: (dynamic args) {
            String purchaseToken = args['purchaseToken'];
            consumeCompleter.complete((purchaseToken));
          });

      Stream purchaseStream =
          GooglePlayConnection.instance.purchaseUpdatedStream;
      StreamSubscription subscription;
      subscription = purchaseStream.listen((_) {
        consumeCompleter.complete(null);
        subscription.cancel();
      }, onDone: () {});
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSkuDetails(skuDetails),
          applicationUserName: accountId);
      await GooglePlayConnection.instance
          .buyConsumable(purchaseParam: purchaseParam, autoConsume: false);
      expect(null, await consumeCompleter.future);
    });
  });

  group('consume purchases', () {
    const String consumeMethodName =
        'BillingClient#consumeAsync(String, ConsumeResponseListener)';
    test('consume purchase async success', () async {
      final BillingResponse expectedCode = BillingResponse.ok;
      stubPlatform.addResponse(
          name: consumeMethodName,
          value: BillingResponseConverter().toJson(expectedCode));

      final BillingResponse responseCode = await GooglePlayConnection.instance
          .consumePurchase(PurchaseDetails.fromPurchase(dummyPurchase));

      expect(responseCode, equals(expectedCode));
    });
  });

  group('complete purchase', () {
    test('calling complete purchase on android should throw', () async {
      expect(() => connection.completePurchase(null), throwsUnsupportedError);
    });
  });
}
