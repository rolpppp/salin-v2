import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/ai/parsed_transaction.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/domain/entities/account.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_review_provider.dart';
import 'package:salin/shared/enums/financial_enums.dart';

void main() {
  late AppDatabase database;
  late AccountRepositoryImpl accountRepository;
  late TransactionRepositoryImpl transactionRepository;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    accountRepository = AccountRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  group('AI Pipeline Integration Tests', () {
    test('Stage transaction and check validation warnings', () {
      final parsed = const ParsedTransaction(
        description: 'Starbucks coffee',
        amountMinor: 15000,
        currency: 'PHP',
        transactionType: 'expense',
        // Missing category no longer triggers a warning — not categorizing
        // must not block saving (see docs/CURRENT_UX_AUDIT.md P0 #2/#3).
      );

      final reviewNotifier = container.read(transactionReviewProvider.notifier);

      reviewNotifier.stageTransaction('Bought Starbucks coffee 150', parsed);

      final stagedItems = container.read(transactionReviewProvider);
      expect(stagedItems.length, 1);
      expect(stagedItems.first.rawInput, 'Bought Starbucks coffee 150');
      expect(stagedItems.first.transaction.description, 'Starbucks coffee');
      expect(stagedItems.first.warnings, isEmpty);
    });

    test('Edit transaction and verify warning updates', () {
      final parsed = const ParsedTransaction(
        description: 'Starbucks coffee',
        // Missing amount triggers a warning that editing must clear —
        // category alone no longer produces a warning to clear.
        currency: 'PHP',
        transactionType: 'expense',
      );

      final reviewNotifier = container.read(transactionReviewProvider.notifier);
      reviewNotifier.stageTransaction('Bought Starbucks coffee 150', parsed);

      var staged = container.read(transactionReviewProvider).first;
      expect(staged.warnings.length, 1);
      expect(staged.warnings, contains('Amount must be greater than zero.'));

      // User edits item to add the missing amount and a category
      final updated = staged.transaction.copyWith(amountMinor: 15000, category: 'cat_food');
      reviewNotifier.updateItem(staged.id, updated);

      staged = container.read(transactionReviewProvider).first;
      expect(staged.transaction.category, 'cat_food');
      expect(staged.warnings, isEmpty); // Warning should be cleared
    });

    test('Confirm staged transaction and check database entry & balance recalculation', () async {
      // Setup account
      final account = Account(
        id: 'acc_cash',
        name: 'Wallet',
        accountType: AccountType.cash,
        openingBalanceMinor: 100000, // ₱1,000.00
        currency: 'PHP',
        icon: 'cash',
        displayOrder: 1,
        isArchived: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      final parsed = const ParsedTransaction(
        description: 'Starbucks coffee',
        amountMinor: 15000,
        currency: 'PHP',
        transactionType: 'expense',
        category: 'cat_food',
      );

      final reviewNotifier = container.read(transactionReviewProvider.notifier);
      reviewNotifier.stageTransaction('Bought Starbucks coffee 150', parsed);

      final stagedId = container.read(transactionReviewProvider).first.id;

      // Confirm item
      await reviewNotifier.confirmItem(stagedId, accountId: 'acc_cash');

      // Review queue should be empty
      expect(container.read(transactionReviewProvider), isEmpty);

      // Entry should exist in DB
      final entries = await transactionRepository.getAllLedgerEntries();
      expect(entries.length, 1);
      expect(entries.first.note, contains('Starbucks coffee'));
      expect(entries.first.amountMinor, 15000);
      expect(entries.first.origin, LedgerOrigin.quickAdd);

      // Balance should be: 1000.00 - 150.00 = 850.00 (85000 minor)
      final balance = await accountRepository.watchBalance('acc_cash').first;
      expect(balance, 85000);
    });

    test('Discard transaction', () {
      final parsed = const ParsedTransaction(
        description: 'Starbucks coffee',
        amountMinor: 15000,
        currency: 'PHP',
        transactionType: 'expense',
      );

      final reviewNotifier = container.read(transactionReviewProvider.notifier);
      reviewNotifier.stageTransaction('Bought Starbucks coffee 150', parsed);

      final stagedId = container.read(transactionReviewProvider).first.id;

      // Discard item
      reviewNotifier.discardItem(stagedId);

      expect(container.read(transactionReviewProvider), isEmpty);
    });

    test('Stage and Confirm Multiple Staged Transactions', () async {
      // 1. Setup account
      final account = Account(
        id: 'acc_cash',
        name: 'Wallet',
        accountType: AccountType.cash,
        openingBalanceMinor: 100000, // ₱1,000.00
        currency: 'PHP',
        icon: 'cash',
        displayOrder: 1,
        isArchived: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      final reviewNotifier = container.read(transactionReviewProvider.notifier);

      // 2. Stage two valid transactions (no warnings)
      final parsed1 = const ParsedTransaction(
        description: 'Lunch Jollibee',
        amountMinor: 15000,
        currency: 'PHP',
        transactionType: 'expense',
        category: 'cat_food',
      );
      final parsed2 = const ParsedTransaction(
        description: 'Grab Car',
        amountMinor: 25000,
        currency: 'PHP',
        transactionType: 'expense',
        category: 'cat_transport',
      );

      reviewNotifier.stageTransaction('Jollibee 150', parsed1);
      reviewNotifier.stageTransaction('Grab 250', parsed2);

      expect(container.read(transactionReviewProvider).length, 2);

      // 3. Confirm all valid items
      await reviewNotifier.confirmAll(accountId: 'acc_cash');

      // Staging queue should be empty
      expect(container.read(transactionReviewProvider), isEmpty);

      // Both entries should exist in DB
      final entries = await transactionRepository.getAllLedgerEntries();
      expect(entries.length, 2);
      expect(entries.any((e) => e.note?.contains('Jollibee') ?? false), true);
      expect(entries.any((e) => e.note?.contains('Grab') ?? false), true);

      // Balance should be: 1000.00 - 150.00 - 250.00 = 600.00 (60000 minor)
      final balance = await accountRepository.watchBalance('acc_cash').first;
      expect(balance, 60000);
    });
  });
}
