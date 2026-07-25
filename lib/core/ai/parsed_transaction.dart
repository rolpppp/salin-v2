import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_transaction.freezed.dart';
part 'parsed_transaction.g.dart';

@freezed
abstract class ParsedTransaction with _$ParsedTransaction {
  const factory ParsedTransaction({
    required String description,
    int? amountMinor,
    required String currency,
    required String transactionType,
    String? category,
    DateTime? transactionDate,
    String? account,
    String? merchant,
    String? notes,
    bool? recurring,
    bool? debt,
    bool? split,
  }) = _ParsedTransaction;

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) => _$ParsedTransactionFromJson(json);
}
