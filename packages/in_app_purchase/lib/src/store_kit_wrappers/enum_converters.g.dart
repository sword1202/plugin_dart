// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_converters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SerializedEnums _$_SerializedEnumsFromJson(Map json) {
  return _SerializedEnums()
    ..response = _$enumDecode(
        _$SKPaymentTransactionStateWrapperEnumMap, json['response']);
}

Map<String, dynamic> _$_SerializedEnumsToJson(_SerializedEnums instance) =>
    <String, dynamic>{
      'response': _$SKPaymentTransactionStateWrapperEnumMap[instance.response]
    };

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

const _$SKPaymentTransactionStateWrapperEnumMap =
    <SKPaymentTransactionStateWrapper, dynamic>{
  SKPaymentTransactionStateWrapper.purchasing: 0,
  SKPaymentTransactionStateWrapper.purchased: 1,
  SKPaymentTransactionStateWrapper.failed: 2,
  SKPaymentTransactionStateWrapper.restored: 3,
  SKPaymentTransactionStateWrapper.deferred: 4
};
