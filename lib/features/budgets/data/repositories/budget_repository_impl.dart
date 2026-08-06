import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final AppDatabase _db;

  BudgetRepositoryImpl(this._db);

  // Mappers
  Budget _mapBudgetRowToDomain(BudgetRow row) {
    return Budget(
      id: row.id,
      name: row.name,
      limitMinor: row.limitMinor,
      period: BudgetPeriod.values[row.period],
      startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate, isUtc: true),
      endDate: DateTime.fromMillisecondsSinceEpoch(row.endDate, isUtc: true),
      rolloverEnabled: row.rolloverEnabled,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true) : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  BudgetsCompanion _mapBudgetDomainToCompanion(Budget domain) {
    return BudgetsCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      limitMinor: Value(domain.limitMinor),
      period: Value(domain.period.index),
      startDate: Value(domain.startDate.millisecondsSinceEpoch),
      endDate: Value(domain.endDate.millisecondsSinceEpoch),
      rolloverEnabled: Value(domain.rolloverEnabled),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  BudgetCategory _mapBudgetCategoryRowToDomain(BudgetCategoryRow row) {
    return BudgetCategory(
      id: row.id,
      budgetId: row.budgetId,
      categoryId: row.categoryId,
      limitMinor: row.limitMinor,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  BudgetCategoriesCompanion _mapBudgetCategoryDomainToCompanion(BudgetCategory domain) {
    return BudgetCategoriesCompanion(
      id: Value(domain.id),
      budgetId: Value(domain.budgetId),
      categoryId: Value(domain.categoryId),
      limitMinor: Value(domain.limitMinor),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
    );
  }

  @override
  Future<void> create(Budget budget, List<BudgetCategory> categories) async {
    await _db.transaction(() async {
      await _db.into(_db.budgets).insert(_mapBudgetDomainToCompanion(budget));
      for (final cat in categories) {
        await _db.into(_db.budgetCategories).insert(_mapBudgetCategoryDomainToCompanion(cat));
      }
    });
  }

  @override
  Future<void> update(Budget budget, List<BudgetCategory> categories) async {
    await _db.transaction(() async {
      await (_db.update(_db.budgets)..where((t) => t.id.equals(budget.id)))
          .write(_mapBudgetDomainToCompanion(budget));
      
      // Delete old budget category mappings and insert the new ones
      await (_db.delete(_db.budgetCategories)..where((t) => t.budgetId.equals(budget.id))).go();
      
      for (final cat in categories) {
        await _db.into(_db.budgetCategories).insert(_mapBudgetCategoryDomainToCompanion(cat));
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.budgets)..where((t) => t.id.equals(id))).write(
        BudgetsCompanion(
          deletedAt: Value(nowMs),
          syncStatus: Value(SyncStatus.pendingUpload.index),
        ),
      );
    });
  }

  @override
  Future<Budget?> getById(String id) async {
    final query = _db.select(_db.budgets)..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapBudgetRowToDomain(row) : null;
  }

  @override
  Future<List<Budget>> getAll() async {
    final query = _db.select(_db.budgets)..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapBudgetRowToDomain).toList();
  }

  @override
  Stream<List<Budget>> watchAllActive() {
    final query = _db.select(_db.budgets)..where((t) => t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapBudgetRowToDomain).toList());
  }

  @override
  Stream<List<BudgetCategory>> watchCategoriesForBudget(String budgetId) {
    final query = _db.select(_db.budgetCategories)..where((t) => t.budgetId.equals(budgetId));
    return query.watch().map((rows) => rows.map(_mapBudgetCategoryRowToDomain).toList());
  }

  @override
  Future<List<BudgetCategory>> getCategoriesForBudget(String budgetId) async {
    final query = _db.select(_db.budgetCategories)..where((t) => t.budgetId.equals(budgetId));
    final rows = await query.get();
    return rows.map(_mapBudgetCategoryRowToDomain).toList();
  }
}
