import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/financial_enums.dart';

part 'debt.freezed.dart';
part 'debt.g.dart';

@freezed
abstract class Debt with _$Debt {
  const factory Debt({
    required String id,
    required String contactId,
    required bool isLent,
    String? originLedgerEntryId,
    required int principalMinor,
    DateTime? dueDate,
    required DebtStatus status,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) = _Debt;

  factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);
}
