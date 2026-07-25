import '../entities/budget.dart';
import '../entities/budget_category.dart';

abstract class BudgetRepository {
  Future<void> create(Budget budget, List<BudgetCategory> categories);
  Future<void> update(Budget budget, List<BudgetCategory> categories);
  Future<void> delete(String id);
  Future<Budget?> getById(String id);
  Future<List<Budget>> getAll();
  Stream<List<Budget>> watchAllActive();
  Stream<List<BudgetCategory>> watchCategoriesForBudget(String budgetId);
  Future<List<BudgetCategory>> getCategoriesForBudget(String budgetId);
}
