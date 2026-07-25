// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Debt _$DebtFromJson(Map<String, dynamic> json) => _Debt(
  id: json['id'] as String,
  contactId: json['contactId'] as String,
  isLent: json['isLent'] as bool,
  originLedgerEntryId: json['originLedgerEntryId'] as String?,
  principalMinor: (json['principalMinor'] as num).toInt(),
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  status: $enumDecode(_$DebtStatusEnumMap, json['status']),
  note: json['note'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
);

Map<String, dynamic> _$DebtToJson(_Debt instance) => <String, dynamic>{
  'id': instance.id,
  'contactId': instance.contactId,
  'isLent': instance.isLent,
  'originLedgerEntryId': instance.originLedgerEntryId,
  'principalMinor': instance.principalMinor,
  'dueDate': instance.dueDate?.toIso8601String(),
  'status': _$DebtStatusEnumMap[instance.status]!,
  'note': instance.note,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$DebtStatusEnumMap = {
  DebtStatus.active: 'active',
  DebtStatus.paid: 'paid',
  DebtStatus.cancelled: 'cancelled',
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
