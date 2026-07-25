// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LedgerEntry _$LedgerEntryFromJson(Map<String, dynamic> json) => _LedgerEntry(
  id: json['id'] as String,
  accountId: json['accountId'] as String,
  categoryId: json['categoryId'] as String?,
  recurringInstanceId: json['recurringInstanceId'] as String?,
  debtId: json['debtId'] as String?,
  splitId: json['splitId'] as String?,
  transferId: json['transferId'] as String?,
  amountMinor: (json['amountMinor'] as num).toInt(),
  direction: $enumDecode(_$MoneyDirectionEnumMap, json['direction']),
  origin: $enumDecode(_$LedgerOriginEnumMap, json['origin']),
  occurredAt: DateTime.parse(json['occurredAt'] as String),
  note: json['note'] as String?,
  metadataJson: json['metadataJson'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
);

Map<String, dynamic> _$LedgerEntryToJson(_LedgerEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountId': instance.accountId,
      'categoryId': instance.categoryId,
      'recurringInstanceId': instance.recurringInstanceId,
      'debtId': instance.debtId,
      'splitId': instance.splitId,
      'transferId': instance.transferId,
      'amountMinor': instance.amountMinor,
      'direction': _$MoneyDirectionEnumMap[instance.direction]!,
      'origin': _$LedgerOriginEnumMap[instance.origin]!,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'note': instance.note,
      'metadataJson': instance.metadataJson,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
    };

const _$MoneyDirectionEnumMap = {
  MoneyDirection.inflow: 'inflow',
  MoneyDirection.outflow: 'outflow',
};

const _$LedgerOriginEnumMap = {
  LedgerOrigin.manual: 'manual',
  LedgerOrigin.quickAdd: 'quickAdd',
  LedgerOrigin.recurring: 'recurring',
  LedgerOrigin.transfer: 'transfer',
  LedgerOrigin.debtSettlement: 'debtSettlement',
  LedgerOrigin.splitSettlement: 'splitSettlement',
  LedgerOrigin.adjustment: 'adjustment',
  LedgerOrigin.import: 'import',
  LedgerOrigin.migration: 'migration',
};

const _$SyncStatusEnumMap = {
  SyncStatus.localOnly: 'localOnly',
  SyncStatus.pendingUpload: 'pendingUpload',
  SyncStatus.synced: 'synced',
  SyncStatus.pendingDelete: 'pendingDelete',
  SyncStatus.conflicted: 'conflicted',
};
