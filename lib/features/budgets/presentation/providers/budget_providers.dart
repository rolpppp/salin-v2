import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../transactions/domain/entities/category.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';

class CategoryBudgetSummary {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final int limitMinor;
  final int spentMinor;

  const CategoryBudgetSummary({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.limitMinor,
    required this.spentMinor,
  });

  int get remainingMinor => limitMinor - spentMinor;
  double get progress => limitMinor > 0 ? spentMinor / limitMinor : 0.0;
  bool get isOverspent => spentMinor > limitMinor;
}

class BudgetSummary {
  final Budget budget;
  final int totalLimitMinor;
  final int totalSpentMinor;
  final List<CategoryBudgetSummary> categorySummaries;

  const BudgetSummary({
    required this.budget,
    required this.totalLimitMinor,
    required this.totalSpentMinor,
    required this.categorySummaries,
  });

  int get remainingMinor => totalLimitMinor - totalSpentMinor;
  double get progress => totalLimitMinor > 0 ? totalSpentMinor / totalLimitMinor : 0.0;
  bool get isOverspent => totalSpentMinor > totalLimitMinor;
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(db);
});

final budgetsListProvider = StreamProvider<List<Budget>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.watchAllActive();
});

final activeBudgetProvider = Provider<AsyncValue<Budget?>>((ref) {
  final budgetsAsync = ref.watch(budgetsListProvider);
  return budgetsAsync.whenData((list) {
    final now = DateTime.now();
    for (final b in list) {
      if (b.startDate.isBefore(now) && b.endDate.isAfter(now)) {
        return b;
      }
    }
    return list.isNotEmpty ? list.first : null;
  });
});

final budgetDetailsProvider = StreamProvider.family<Budget?, String>((ref, budgetId) {
  return ref.watch(budgetRepositoryProvider).watchAllActive().map(
    (list) {
      for (final b in list) {
        if (b.id == budgetId) return b;
      }
      return null;
    },
  );
});

final budgetCategoryLimitsProvider = StreamProvider.family<List<BudgetCategory>, String>((ref, budgetId) {
  return ref.watch(budgetRepositoryProvider).watchCategoriesForBudget(budgetId);
});

final budgetSummaryProvider = Provider.family<AsyncValue<BudgetSummary>, String>((ref, budgetId) {
  final budgetAsync = ref.watch(budgetDetailsProvider(budgetId));
  final limitsAsync = ref.watch(budgetCategoryLimitsProvider(budgetId));
  final categoriesAsync = ref.watch(categoriesListProvider);
  final entriesAsync = ref.watch(ledgerEntriesListProvider);

  return budgetAsync.when(
    data: (budget) {
      if (budget == null) {
        return AsyncValue.error(Exception("Budget not found"), StackTrace.current);
      }
      return limitsAsync.when(
        data: (limits) {
          return categoriesAsync.when(
            data: (categories) {
              return entriesAsync.when(
                data: (entries) {
                  // Filter qualified expenses:
                  // - Within budget date range
                  // - Outflow direction
                  // - Matches categories inside the budget
                  final startMs = budget.startDate.millisecondsSinceEpoch;
                  final endMs = budget.endDate.millisecondsSinceEpoch;

                  final limitCategoryIds = limits.map((l) => l.categoryId).toSet();

                  final qualifiedExpenses = entries.where((e) {
                    final occurredMs = e.occurredAt.millisecondsSinceEpoch;
                    return e.direction == MoneyDirection.outflow &&
                           occurredMs >= startMs &&
                           occurredMs <= endMs &&
                           e.categoryId != null &&
                           (limitCategoryIds.isEmpty || limitCategoryIds.contains(e.categoryId));
                  }).toList();

                  int totalLimit = budget.limitMinor ?? 0;
                  int totalSpent = 0;
                  final categorySummaries = <CategoryBudgetSummary>[];

                  if (limits.isNotEmpty) {
                    totalLimit = 0;
                    for (final limit in limits) {
                      totalLimit += limit.limitMinor;

                      // Calculate spent for this category
                      final catSpent = qualifiedExpenses
                          .where((e) => e.categoryId == limit.categoryId)
                          .fold<int>(0, (sum, e) => sum + e.amountMinor);

                      totalSpent += catSpent;

                      // Find category details
                      final category = categories.firstWhere(
                        (c) => c.id == limit.categoryId,
                        orElse: () => Category(
                          id: limit.categoryId,
                          name: 'Unknown',
                          icon: 'category',
                          color: '#808080',
                          categoryType: CategoryType.expense,
                          isSystem: false,
                          displayOrder: 99,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          syncStatus: SyncStatus.localOnly,
                        ),
                      );

                      categorySummaries.add(CategoryBudgetSummary(
                        categoryId: limit.categoryId,
                        categoryName: category.name,
                        categoryIcon: category.icon,
                        categoryColor: category.color,
                        limitMinor: limit.limitMinor,
                        spentMinor: catSpent,
                      ));
                    }
                  } else {
                    totalSpent = qualifiedExpenses.fold<int>(0, (sum, e) => sum + e.amountMinor);
                  }

                  return AsyncValue.data(BudgetSummary(
                    budget: budget,
                    totalLimitMinor: totalLimit,
                    totalSpentMinor: totalSpent,
                    categorySummaries: categorySummaries,
                  ));
                },
                loading: () => const AsyncValue.loading(),
                error: (e, s) => AsyncValue.error(e, s),
              );
            },
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
