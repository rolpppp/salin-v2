// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Split _$SplitFromJson(Map<String, dynamic> json) => _Split(
  id: json['id'] as String,
  title: json['title'] as String,
  originLedgerEntryId: json['originLedgerEntryId'] as String?,
  totalMinor: (json['totalMinor'] as num).toInt(),
  status: $enumDecode(_$SplitStatusEnumMap, json['status']),
  note: json['note'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
);

Map<String, dynamic> _$SplitToJson(_Split instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'originLedgerEntryId': instance.originLedgerEntryId,
  'totalMinor': instance.totalMinor,
  'status': _$SplitStatusEnumMap[instance.status]!,
  'note': instance.note,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$SplitStatusEnumMap = {
  SplitStatus.active: 'active',
  SplitStatus.settled: 'settled',
  SplitStatus.cancelled: 'cancelled',
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
