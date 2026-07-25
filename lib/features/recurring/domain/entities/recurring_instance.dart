import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/financial_enums.dart';

part 'recurring_instance.freezed.dart';
part 'recurring_instance.g.dart';

@freezed
abstract class RecurringInstance with _$RecurringInstance {
  const factory RecurringInstance({
    required String id,
    required String recurringRuleId,
    required DateTime scheduledDate,
    String? ledgerEntryId,
    required RecurringInstanceStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    required SyncStatus syncStatus,
  }) = _RecurringInstance;

  factory RecurringInstance.fromJson(Map<String, dynamic> json) => _$RecurringInstanceFromJson(json);
}
