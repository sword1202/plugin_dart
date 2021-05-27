// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/src/billing_client_wrappers/enum_converters.dart';
import 'package:in_app_purchase_android/src/channel.dart';
import 'package:in_app_purchase_android/src/in_app_purchase_android_platform_addition.dart';

import 'billing_client_wrappers/purchase_wrapper_test.dart';
import 'stub_in_app_purchase_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final StubInAppPurchasePlatform stubPlatform = StubInAppPurchasePlatform();
  late InAppPurchaseAndroidPlatformAddition iapAndroidPlatformAddition;
  const String startConnectionCall =
      'BillingClient#startConnection(BillingClientStateListener)';
  const String endConnectionCall = 'BillingClient#endConnection()';

  setUpAll(() {
    channel.setMockMethodCallHandler(stubPlatform.fakeMethodCallHandler);
  });

  setUp(() {
    widgets.WidgetsFlutterBinding.ensureInitialized();

    InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();

    const String debugMessage = 'dummy message';
    final BillingResponse responseCode = BillingResponse.ok;
    final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
        responseCode: responseCode, debugMessage: debugMessage);
    stubPlatform.addResponse(
        name: startConnectionCall,
        value: buildBillingResultMap(expectedBillingResult));
    stubPlatform.addResponse(name: endConnectionCall, value: null);
    iapAndroidPlatformAddition =
        InAppPurchaseAndroidPlatformAddition(BillingClient((_) {}));
  });

  group('consume purchases', () {
    const String consumeMethodName =
        'BillingClient#consumeAsync(String, ConsumeResponseListener)';
    test('consume purchase async success', () async {
      final BillingResponse expectedCode = BillingResponse.ok;
      const String debugMessage = 'dummy message';
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: expectedCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
        name: consumeMethodName,
        value: buildBillingResultMap(expectedBillingResult),
      );
      final BillingResultWrapper billingResultWrapper =
          await iapAndroidPlatformAddition.consumePurchase(
              GooglePlayPurchaseDetails.fromPurchase(dummyPurchase));

      expect(billingResultWrapper, equals(expectedBillingResult));
    });
  });

  group('queryPastPurchase', () {
    group('queryPurchaseDetails', () {
      const String queryMethodName = 'BillingClient#queryPurchases(String)';
      test('handles error', () async {
        const String debugMessage = 'dummy message';
        final BillingResponse responseCode = BillingResponse.developerError;
        final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
            responseCode: responseCode, debugMessage: debugMessage);

        stubPlatform
            .addResponse(name: queryMethodName, value: <dynamic, dynamic>{
          'billingResult': buildBillingResultMap(expectedBillingResult),
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'purchasesList': <Map<String, dynamic>>[]
        });
        final QueryPurchaseDetailsResponse response =
            await iapAndroidPlatformAddition.queryPastPurchases();
        expect(response.pastPurchases, isEmpty);
        expect(response.error, isNotNull);
        expect(
            response.error!.message, BillingResponse.developerError.toString());
        expect(response.error!.source, kIAPSource);
      });

      test('returns SkuDetailsResponseWrapper', () async {
        const String debugMessage = 'dummy message';
        final BillingResponse responseCode = BillingResponse.ok;
        final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
            responseCode: responseCode, debugMessage: debugMessage);

        stubPlatform
            .addResponse(name: queryMethodName, value: <String, dynamic>{
          'billingResult': buildBillingResultMap(expectedBillingResult),
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'purchasesList': <Map<String, dynamic>>[
            buildPurchaseMap(dummyPurchase),
          ]
        });

        // Since queryPastPurchases makes 2 platform method calls (one for each SkuType), the result will contain 2 dummyWrapper instead
        // of 1.
        final QueryPurchaseDetailsResponse response =
            await iapAndroidPlatformAddition.queryPastPurchases();
        expect(response.error, isNull);
        expect(response.pastPurchases.first.purchaseID, dummyPurchase.orderId);
      });

      test('should store platform exception in the response', () async {
        const String debugMessage = 'dummy message';

        final BillingResponse responseCode = BillingResponse.developerError;
        final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
            responseCode: responseCode, debugMessage: debugMessage);
        stubPlatform.addResponse(
            name: queryMethodName,
            value: <dynamic, dynamic>{
              'responseCode': BillingResponseConverter().toJson(responseCode),
              'billingResult': buildBillingResultMap(expectedBillingResult),
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
            await iapAndroidPlatformAddition.queryPastPurchases();
        expect(response.pastPurchases, isEmpty);
        expect(response.error, isNotNull);
        expect(response.error!.code, 'error_code');
        expect(response.error!.message, 'error_message');
        expect(response.error!.details, {'info': 'error_info'});
      });
    });
  });
}
