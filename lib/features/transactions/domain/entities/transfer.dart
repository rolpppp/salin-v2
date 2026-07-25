import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/financial_enums.dart';

part 'transfer.freezed.dart';
part 'transfer.g.dart';

@freezed
abstract class Transfer with _$Transfer {
  const factory Transfer({
    required String id,
    required String fromAccountId,
    required String toAccountId,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) = _Transfer;

  factory Transfer.fromJson(Map<String, dynamic> json) => _$TransferFromJson(json);
}
