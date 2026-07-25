import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/financial_enums.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,
    required String name,
    required AccountType accountType,
    required int openingBalanceMinor,
    required String currency,
    required String icon,
    String? color,
    required int displayOrder,
    required bool isArchived,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}
