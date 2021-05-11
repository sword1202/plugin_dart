// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:in_app_purchase_android/src/billing_client_wrappers/enum_converters.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import '../../billing_client_wrappers.dart';
import '../in_app_purchase_android_platform.dart';

/// The class represents the information of a purchase made using Google Play.
class GooglePlayPurchaseDetails extends PurchaseDetails {
  /// Creates a new Google Play specific purchase details object with the
  /// provided details.
  GooglePlayPurchaseDetails({
    String? purchaseID,
    required String productID,
    required PurchaseVerificationData verificationData,
    required String? transactionDate,
    required this.billingClientPurchase,
    required PurchaseStatus status,
  }) : super(
            productID: productID,
            purchaseID: purchaseID,
            transactionDate: transactionDate,
            verificationData: verificationData,
            status: status) {
    this.status = status;
  }

  /// Points back to the [PurchaseWrapper] which was used to generate this
  /// [GooglePlayPurchaseDetails] object.
  final PurchaseWrapper billingClientPurchase;

  late PurchaseStatus _status;

  /// The status that this [PurchaseDetails] is currently on.
  PurchaseStatus get status => _status;
  set status(PurchaseStatus status) {
    _pendingCompletePurchase = status == PurchaseStatus.purchased;
    _status = status;
  }

  bool _pendingCompletePurchase = false;
  bool get pendingCompletePurchase => _pendingCompletePurchase;

  /// Generate a [PurchaseDetails] object based on an Android [Purchase] object.
  factory GooglePlayPurchaseDetails.fromPurchase(PurchaseWrapper purchase) {
    final GooglePlayPurchaseDetails purchaseDetails = GooglePlayPurchaseDetails(
      purchaseID: purchase.orderId,
      productID: purchase.sku,
      verificationData: PurchaseVerificationData(
          localVerificationData: purchase.originalJson,
          serverVerificationData: purchase.purchaseToken,
          source: kIAPSource),
      transactionDate: purchase.purchaseTime.toString(),
      billingClientPurchase: purchase,
      status: PurchaseStateConverter().toPurchaseStatus(purchase.purchaseState),
    );

    if (purchaseDetails.status == PurchaseStatus.error) {
      purchaseDetails.error = IAPError(
        source: kIAPSource,
        code: kPurchaseErrorCode,
        message: '',
      );
    }

    return purchaseDetails;
  }
}
