// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_instance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringInstance _$RecurringInstanceFromJson(Map<String, dynamic> json) =>
    _RecurringInstance(
      id: json['id'] as String,
      recurringRuleId: json['recurringRuleId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      ledgerEntryId: json['ledgerEntryId'] as String?,
      status: $enumDecode(_$RecurringInstanceStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
    );

Map<String, dynamic> _$RecurringInstanceToJson(_RecurringInstance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recurringRuleId': instance.recurringRuleId,
      'scheduledDate': instance.scheduledDate.toIso8601String(),
      'ledgerEntryId': instance.ledgerEntryId,
      'status': _$RecurringInstanceStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
    };

const _$RecurringInstanceStatusEnumMap = {
  RecurringInstanceStatus.pending: 'pending',
  RecurringInstanceStatus.generated: 'generated',
  RecurringInstanceStatus.paid: 'paid',
  RecurringInstanceStatus.skipped: 'skipped',
  RecurringInstanceStatus.cancelled: 'cancelled',
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
