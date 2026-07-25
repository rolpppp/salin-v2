import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/financial_enums.dart';

part 'recurring_rule.freezed.dart';
part 'recurring_rule.g.dart';

@freezed
abstract class RecurringRule with _$RecurringRule {
  const factory RecurringRule({
    required String id,
    required String title,
    required String accountId,
    String? categoryId,
    required int amountMinor,
    required MoneyDirection direction,
    required RecurringFrequency frequency,
    required int interval,
    required DateTime startDate,
    DateTime? endDate,
    required bool autoGenerate,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) = _RecurringRule;

  factory RecurringRule.fromJson(Map<String, dynamic> json) => _$RecurringRuleFromJson(json);
}
