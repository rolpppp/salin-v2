// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  id: json['id'] as String,
  name: json['name'] as String,
  period: $enumDecode(_$BudgetPeriodEnumMap, json['period']),
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  rolloverEnabled: json['rolloverEnabled'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'period': _$BudgetPeriodEnumMap[instance.period]!,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'rolloverEnabled': instance.rolloverEnabled,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$BudgetPeriodEnumMap = {
  BudgetPeriod.weekly: 'weekly',
  BudgetPeriod.monthly: 'monthly',
  BudgetPeriod.quarterly: 'quarterly',
  BudgetPeriod.yearly: 'yearly',
  BudgetPeriod.custom: 'custom',
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
