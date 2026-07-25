import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/domain/entities/account.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/domain/entities/ledger_entry.dart';
import 'package:salin/features/transactions/domain/entities/transfer.dart';
import 'package:salin/shared/enums/financial_enums.dart';

void main() {
  late AppDatabase database;
  late AccountRepositoryImpl accountRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() {
    // Open in-memory database for testing
    database = AppDatabase(NativeDatabase.memory());
    accountRepository = AccountRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Salin Core Ledger Engine Tests', () {
    test('Create account and check initial balance', () async {
      final account = Account(
        id: 'acc_1',
        name: 'GCash',
        accountType: AccountType.eWallet,
        openingBalanceMinor: 500000, // ₱5,000.00
        currency: 'PHP',
        icon: 'wallet',
        displayOrder: 1,
        isArchived: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );

      await accountRepository.create(account);

      final fetched = await accountRepository.getById('acc_1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'GCash');
      expect(fetched.openingBalanceMinor, 500000);

      // Check reactive balance calculation
      final balance = await accountRepository.watchBalance('acc_1').first;
      expect(balance, 500000);
    });

    test('Record income and expense transactions and verify computed balance', () async {
      final account = Account(
        id: 'acc_gcash',
        name: 'GCash',
        accountType: AccountType.eWallet,
        openingBalanceMinor: 100000, // ₱1,000.00
        currency: 'PHP',
        icon: 'wallet',
        displayOrder: 1,
        isArchived: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      // Add income (₱500)
      final income = LedgerEntry(
        id: 'tx_salary',
        accountId: 'acc_gcash',
        categoryId: 'cat_salary',
        amountMinor: 50000,
        direction: MoneyDirection.inflow,
        origin: LedgerOrigin.manual,
        occurredAt: DateTime.now().toUtc(),
        note: 'Freelance pay',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await transactionRepository.createLedgerEntry(income);

      // Add expense (₱200)
      final expense = LedgerEntry(
        id: 'tx_food',
        accountId: 'acc_gcash',
        categoryId: 'cat_food',
        amountMinor: 20000,
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.manual,
        occurredAt: DateTime.now().toUtc(),
        note: 'Lunch Jollibee',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await transactionRepository.createLedgerEntry(expense);

      // Balance should be: 1000.00 + 500.00 - 200.00 = 1300.00 (130000 minor)
      final balance = await accountRepository.watchBalance('acc_gcash').first;
      expect(balance, 130000);
    });

    test('Record Transfer between accounts and check both balances', () async {
      final source = Account(
        id: 'acc_bpi',
        name: 'BPI Bank',
        accountType: AccountType.bank,
        openingBalanceMinor: 200000, // ₱2,000.00
        currency: 'PHP',
        icon: 'bank',
        displayOrder: 1,
        isArchived: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );

      final dest = Account(
        id: 'acc_gcash',
        name: 'GCash',
        accountType: AccountType.eWallet,
        openingBalanceMinor: 50000, // ₱500.00
        currency: 'PHP',
        icon: 'wallet',
        displayOrder: 2,
        isArchived: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );

      await accountRepository.create(source);
      await accountRepository.create(dest);

      // Perform transfer of ₱300 from BPI to GCash
      final transfer = Transfer(
        id: 'tr_1',
        fromAccountId: 'acc_bpi',
        toAccountId: 'acc_gcash',
        note: 'Load GCash',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );

      await transactionRepository.createTransfer(transfer, amountMinor: 30000, occurredAt: DateTime.now().toUtc());

      // Source balance should be 2000.00 - 300.00 = 1700.00 (170000 minor)
      final sourceBalance = await accountRepository.watchBalance('acc_bpi').first;
      expect(sourceBalance, 170000);

      // Destination balance should be 500.00 + 300.00 = 800.00 (80000 minor)
      final destBalance = await accountRepository.watchBalance('acc_gcash').first;
      expect(destBalance, 80000);

      // Double check that two LedgerEntry records were created
      final entries = await transactionRepository.getAllLedgerEntries();
      expect(entries.length, 2);
      expect(entries.any((e) => e.direction == MoneyDirection.outflow && e.accountId == 'acc_bpi'), isTrue);
      expect(entries.any((e) => e.direction == MoneyDirection.inflow && e.accountId == 'acc_gcash'), isTrue);
    });

    test('Delete a transaction and verify balance updates', () async {
      final account = Account(
        id: 'acc_cash',
        name: 'Cash Pocket',
        accountType: AccountType.cash,
        openingBalanceMinor: 50000, // ₱500.00
        currency: 'PHP',
        icon: 'cash',
        displayOrder: 1,
        isArchived: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      final entry = LedgerEntry(
        id: 'tx_snack',
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        amountMinor: 10000, // ₱100.00
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.manual,
        occurredAt: DateTime.now().toUtc(),
        note: 'Snacks',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await transactionRepository.createLedgerEntry(entry);

      // Balance should be: 500.00 - 100.00 = 400.00
      var balance = await accountRepository.watchBalance('acc_cash').first;
      expect(balance, 40000);

      // Delete transaction
      await transactionRepository.deleteLedgerEntry('tx_snack');

      // Balance should restore to 500.00 because deleted transaction is excluded
      balance = await accountRepository.watchBalance('acc_cash').first;
      expect(balance, 50000);
    });
  });
}
