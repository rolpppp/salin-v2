import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/financial_enums.dart';

part 'ledger_entry.freezed.dart';
part 'ledger_entry.g.dart';

@freezed
abstract class LedgerEntry with _$LedgerEntry {
  const factory LedgerEntry({
    required String id,
    required String accountId,
    String? categoryId,
    String? recurringInstanceId,
    String? debtId,
    String? splitId,
    String? transferId,
    required int amountMinor,
    required MoneyDirection direction,
    required LedgerOrigin origin,
    required DateTime occurredAt,
    String? note,
    String? metadataJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) = _LedgerEntry;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => _$LedgerEntryFromJson(json);
}
