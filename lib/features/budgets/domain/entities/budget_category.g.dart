// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetCategory _$BudgetCategoryFromJson(Map<String, dynamic> json) =>
    _BudgetCategory(
      id: json['id'] as String,
      budgetId: json['budgetId'] as String,
      categoryId: json['categoryId'] as String,
      limitMinor: (json['limitMinor'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BudgetCategoryToJson(_BudgetCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'budgetId': instance.budgetId,
      'categoryId': instance.categoryId,
      'limitMinor': instance.limitMinor,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
