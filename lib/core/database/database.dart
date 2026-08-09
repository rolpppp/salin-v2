import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/enums/financial_enums.dart';
import 'tables/tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Settings,
    Accounts,
    Categories,
    Budgets,
    BudgetCategories,
    RecurringRules,
    RecurringInstances,
    Contacts,
    Debts,
    Splits,
    SplitParticipants,
    Transfers,
    LedgerEntries,
    Media,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(budgets, budgets.limitMinor);
          }
        },
        onCreate: (m) async {
          await m.createAll();
          
          // Seed initial categories
          final now = DateTime.now().toUtc().millisecondsSinceEpoch;
          
          await batch((b) {
            b.insertAll(categories, [
              CategoriesCompanion.insert(
                id: 'cat_salary',
                name: 'Salary',
                icon: 'salary',
                color: '#3F7D58',
                categoryType: CategoryType.income.index,
                isSystem: true,
                displayOrder: 1,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
              CategoriesCompanion.insert(
                id: 'cat_investments',
                name: 'Investments',
                icon: 'investments',
                color: '#2E6EA6',
                categoryType: CategoryType.income.index,
                isSystem: true,
                displayOrder: 2,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
              CategoriesCompanion.insert(
                id: 'cat_other_income',
                name: 'Other (Income)',
                icon: 'other',
                color: '#8C6A3F',
                categoryType: CategoryType.income.index,
                isSystem: true,
                displayOrder: 3,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
              CategoriesCompanion.insert(
                id: 'cat_food',
                name: 'Food',
                icon: 'food',
                color: '#C98A3D',
                categoryType: CategoryType.expense.index,
                isSystem: true,
                displayOrder: 4,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
              CategoriesCompanion.insert(
                id: 'cat_transport',
                name: 'Transport',
                icon: 'transport',
                color: '#2E6EA6',
                categoryType: CategoryType.expense.index,
                isSystem: true,
                displayOrder: 5,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
              CategoriesCompanion.insert(
                id: 'cat_rent',
                name: 'Rent',
                icon: 'rent',
                color: '#A83232',
                categoryType: CategoryType.expense.index,
                isSystem: true,
                displayOrder: 6,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
              CategoriesCompanion.insert(
                id: 'cat_utilities',
                name: 'Utilities',
                icon: 'utilities',
                color: '#8C6A3F',
                categoryType: CategoryType.expense.index,
                isSystem: true,
                displayOrder: 7,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
              CategoriesCompanion.insert(
                id: 'cat_entertainment',
                name: 'Entertainment',
                icon: 'entertainment',
                color: '#2E6EA6',
                categoryType: CategoryType.expense.index,
                isSystem: true,
                displayOrder: 8,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
            ]);
          });

          // Seed a default account so a fresh install can log a transaction
          // immediately instead of hitting an empty account picker first.
          await batch((b) {
            b.insertAll(accounts, [
              AccountsCompanion.insert(
                id: 'acc_default_cash',
                name: 'Cash',
                accountType: AccountType.cash.index,
                openingBalanceMinor: 0,
                currency: 'PHP',
                icon: 'cash',
                displayOrder: 0,
                isArchived: false,
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.localOnly.index,
              ),
            ]);
          });
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'salin.db'));



    return NativeDatabase.createInBackground(file);
  });
}
