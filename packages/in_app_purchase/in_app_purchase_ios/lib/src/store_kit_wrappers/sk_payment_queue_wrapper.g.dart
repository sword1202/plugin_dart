// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sk_payment_queue_wrapper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SKError _$SKErrorFromJson(Map json) => SKError(
      code: json['code'] as int? ?? 0,
      domain: json['domain'] as String? ?? '',
      userInfo: (json['userInfo'] as Map?)?.map(
            (k, e) => MapEntry(k as String, e),
          ) ??
          {},
    );

SKPaymentWrapper _$SKPaymentWrapperFromJson(Map json) => SKPaymentWrapper(
      productIdentifier: json['productIdentifier'] as String? ?? '',
      applicationUsername: json['applicationUsername'] as String?,
      requestData: json['requestData'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      simulatesAskToBuyInSandbox:
          json['simulatesAskToBuyInSandbox'] as bool? ?? false,
    );

Map<String, dynamic> _$SKPaymentWrapperToJson(SKPaymentWrapper instance) =>
    <String, dynamic>{
      'productIdentifier': instance.productIdentifier,
      'applicationUsername': instance.applicationUsername,
      'requestData': instance.requestData,
      'quantity': instance.quantity,
      'simulatesAskToBuyInSandbox': instance.simulatesAskToBuyInSandbox,
    };
