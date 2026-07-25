import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/ai/parsed_transaction.dart';

part 'review_item.freezed.dart';

@freezed
abstract class ReviewItem with _$ReviewItem {
  const factory ReviewItem({
    required String id,
    required String rawInput,
    required ParsedTransaction transaction,
    @Default([]) List<String> warnings,
  }) = _ReviewItem;
}
