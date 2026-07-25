import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/financial_enums.dart';

part 'split.freezed.dart';
part 'split.g.dart';

@freezed
abstract class Split with _$Split {
  const factory Split({
    required String id,
    required String title,
    String? originLedgerEntryId,
    required int totalMinor,
    required SplitStatus status,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) = _Split;

  factory Split.fromJson(Map<String, dynamic> json) => _$SplitFromJson(json);
}
