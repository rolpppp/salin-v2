// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transfer _$TransferFromJson(Map<String, dynamic> json) => _Transfer(
  id: json['id'] as String,
  fromAccountId: json['fromAccountId'] as String,
  toAccountId: json['toAccountId'] as String,
  note: json['note'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
);

Map<String, dynamic> _$TransferToJson(_Transfer instance) => <String, dynamic>{
  'id': instance.id,
  'fromAccountId': instance.fromAccountId,
  'toAccountId': instance.toAccountId,
  'note': instance.note,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
