// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringRule _$RecurringRuleFromJson(Map<String, dynamic> json) =>
    _RecurringRule(
      id: json['id'] as String,
      title: json['title'] as String,
      accountId: json['accountId'] as String,
      categoryId: json['categoryId'] as String?,
      amountMinor: (json['amountMinor'] as num).toInt(),
      direction: $enumDecode(_$MoneyDirectionEnumMap, json['direction']),
      frequency: $enumDecode(_$RecurringFrequencyEnumMap, json['frequency']),
      interval: (json['interval'] as num).toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      autoGenerate: json['autoGenerate'] as bool,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
    );

Map<String, dynamic> _$RecurringRuleToJson(_RecurringRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'accountId': instance.accountId,
      'categoryId': instance.categoryId,
      'amountMinor': instance.amountMinor,
      'direction': _$MoneyDirectionEnumMap[instance.direction]!,
      'frequency': _$RecurringFrequencyEnumMap[instance.frequency]!,
      'interval': instance.interval,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'autoGenerate': instance.autoGenerate,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
    };

const _$MoneyDirectionEnumMap = {
  MoneyDirection.inflow: 'inflow',
  MoneyDirection.outflow: 'outflow',
};

const _$RecurringFrequencyEnumMap = {
  RecurringFrequency.daily: 'daily',
  RecurringFrequency.weekly: 'weekly',
  RecurringFrequency.monthly: 'monthly',
  RecurringFrequency.quarterly: 'quarterly',
  RecurringFrequency.yearly: 'yearly',
  RecurringFrequency.custom: 'custom',
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
