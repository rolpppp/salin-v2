// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParsedTransaction _$ParsedTransactionFromJson(Map<String, dynamic> json) =>
    _ParsedTransaction(
      description: json['description'] as String,
      amountMinor: (json['amountMinor'] as num?)?.toInt(),
      currency: json['currency'] as String,
      transactionType: json['transactionType'] as String,
      category: json['category'] as String?,
      transactionDate: json['transactionDate'] == null
          ? null
          : DateTime.parse(json['transactionDate'] as String),
      account: json['account'] as String?,
      merchant: json['merchant'] as String?,
      notes: json['notes'] as String?,
      recurring: json['recurring'] as bool?,
      debt: json['debt'] as bool?,
      split: json['split'] as bool?,
    );

Map<String, dynamic> _$ParsedTransactionToJson(_ParsedTransaction instance) =>
    <String, dynamic>{
      'description': instance.description,
      'amountMinor': instance.amountMinor,
      'currency': instance.currency,
      'transactionType': instance.transactionType,
      'category': instance.category,
      'transactionDate': instance.transactionDate?.toIso8601String(),
      'account': instance.account,
      'merchant': instance.merchant,
      'notes': instance.notes,
      'recurring': instance.recurring,
      'debt': instance.debt,
      'split': instance.split,
    };
