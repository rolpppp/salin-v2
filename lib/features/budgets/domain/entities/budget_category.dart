import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_category.freezed.dart';
part 'budget_category.g.dart';

@freezed
abstract class BudgetCategory with _$BudgetCategory {
  const factory BudgetCategory({
    required String id,
    required String budgetId,
    required String categoryId,
    required int limitMinor,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BudgetCategory;

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => _$BudgetCategoryFromJson(json);
}
