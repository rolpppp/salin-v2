// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: json['id'] as String,
  name: json['name'] as String,
  accountType: $enumDecode(_$AccountTypeEnumMap, json['accountType']),
  openingBalanceMinor: (json['openingBalanceMinor'] as num).toInt(),
  currency: json['currency'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String?,
  displayOrder: (json['displayOrder'] as num).toInt(),
  isArchived: json['isArchived'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'accountType': _$AccountTypeEnumMap[instance.accountType]!,
  'openingBalanceMinor': instance.openingBalanceMinor,
  'currency': instance.currency,
  'icon': instance.icon,
  'color': instance.color,
  'displayOrder': instance.displayOrder,
  'isArchived': instance.isArchived,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$AccountTypeEnumMap = {
  AccountType.cash: 'cash',
  AccountType.bank: 'bank',
  AccountType.savings: 'savings',
  AccountType.eWallet: 'eWallet',
  AccountType.creditCard: 'creditCard',
  AccountType.debitCard: 'debitCard',
  AccountType.investment: 'investment',
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
