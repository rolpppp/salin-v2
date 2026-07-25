import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/domain/entities/account.dart';
import 'package:salin/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:salin/features/budgets/domain/entities/budget.dart';
import 'package:salin/features/budgets/domain/entities/budget_category.dart';
import 'package:salin/features/budgets/presentation/providers/budget_providers.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/domain/entities/ledger_entry.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/shared/enums/financial_enums.dart';

void main() {
  late AppDatabase database;
  late BudgetRepositoryImpl budgetRepository;
  late TransactionRepositoryImpl transactionRepository;
  late AccountRepositoryImpl accountRepository;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    budgetRepository = BudgetRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);
    accountRepository = AccountRepositoryImpl(database);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        budgetRepositoryProvider.overrideWithValue(budgetRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  group('Salin Core Budget Engine Tests', () {
    test('Create budget and retrieve summary details', () async {
      final now = DateTime.now().toUtc();
      final budget = Budget(
        id: 'b_monthly',
        name: 'July Budget',
        period: BudgetPeriod.monthly,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 25)),
        rolloverEnabled: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );

      final limitFood = BudgetCategory(
        id: 'bc_food',
        budgetId: 'b_monthly',
        categoryId: 'cat_food',
        limitMinor: 1000000, // ₱10,000.00
        createdAt: now,
        updatedAt: now,
      );

      final limitTransport = BudgetCategory(
        id: 'bc_trans',
        budgetId: 'b_monthly',
        categoryId: 'cat_transport',
        limitMinor: 300000, // ₱3,000.00
        createdAt: now,
        updatedAt: now,
      );

      await budgetRepository.create(budget, [limitFood, limitTransport]);

      // Await underlying reactive streams to load
      await container.read(budgetsListProvider.future);
      await container.read(budgetDetailsProvider('b_monthly').future);
      await container.read(budgetCategoryLimitsProvider('b_monthly').future);
      await container.read(categoriesListProvider.future);
      await container.read(ledgerEntriesListProvider.future);

      // Verify active budget
      final activeBudget = container.read(activeBudgetProvider).value;
      expect(activeBudget, isNotNull);
      expect(activeBudget!.name, 'July Budget');

      // Verify summary shows zero spent and correct total limit
      final summaryAsync = container.read(budgetSummaryProvider('b_monthly'));
      expect(summaryAsync.value, isNotNull);
      
      final summary = summaryAsync.value!;
      expect(summary.totalLimitMinor, 1300000); // ₱13,000
      expect(summary.totalSpentMinor, 0);
      expect(summary.remainingMinor, 1300000);
      expect(summary.isOverspent, isFalse);
    });

    test('Add qualified expenses and verify reactive budget consumption', () async {
      // Setup GCash account
      final now = DateTime.now().toUtc();
      final account = Account(
        id: 'acc_1',
        name: 'GCash',
        accountType: AccountType.eWallet,
        openingBalanceMinor: 2000000, // ₱20,000.00
        currency: 'PHP',
        icon: 'wallet',
        displayOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      // Create budget (July Budget)
      final budget = Budget(
        id: 'b_july',
        name: 'July Budget',
        period: BudgetPeriod.monthly,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 25)),
        rolloverEnabled: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );

      final limitFood = BudgetCategory(
        id: 'bc_food',
        budgetId: 'b_july',
        categoryId: 'cat_food',
        limitMinor: 500000, // ₱5,000.00
        createdAt: now,
        updatedAt: now,
      );
      await budgetRepository.create(budget, [limitFood]);

      // Add expense inside budget (₱1,500 on Food)
      final exp1 = LedgerEntry(
        id: 'tx_jollibee',
        accountId: 'acc_1',
        categoryId: 'cat_food',
        amountMinor: 150000,
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.manual,
        occurredAt: now,
        note: 'Jollibee family meal',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await transactionRepository.createLedgerEntry(exp1);

      // Add expense outside budget period (Should NOT reduce budget)
      final exp2 = LedgerEntry(
        id: 'tx_old_meal',
        accountId: 'acc_1',
        categoryId: 'cat_food',
        amountMinor: 100000, // ₱1,000
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.manual,
        occurredAt: now.subtract(const Duration(days: 10)), // outside range
        note: 'Old food',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await transactionRepository.createLedgerEntry(exp2);

      // Add expense in different category (Rent, which is not in this budget)
      final exp3 = LedgerEntry(
        id: 'tx_rent',
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amountMinor: 400000, // ₱4,000
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.manual,
        occurredAt: now,
        note: 'July Rent',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await transactionRepository.createLedgerEntry(exp3);

      // Await underlying reactive streams to load
      await container.read(budgetsListProvider.future);
      await container.read(budgetDetailsProvider('b_july').future);
      await container.read(budgetCategoryLimitsProvider('b_july').future);
      await container.read(categoriesListProvider.future);
      await container.read(ledgerEntriesListProvider.future);

      // Verify that total spent on this budget is exactly ₱1,500 (150,000 minor)
      final summaryAsync = container.read(budgetSummaryProvider('b_july'));
      expect(summaryAsync.value, isNotNull);
      
      final summary = summaryAsync.value!;
      expect(summary.totalSpentMinor, 150000);
      expect(summary.remainingMinor, 350000); // 5,000 - 1,500 = 3,500 (350,000 minor)
      expect(summary.categorySummaries.first.spentMinor, 150000);
    });
  });
}
