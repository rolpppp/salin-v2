import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/domain/entities/account.dart';
import 'package:salin/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:salin/features/contacts/domain/entities/contact.dart';
import 'package:salin/features/contacts/presentation/providers/contact_providers.dart';
import 'package:salin/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:salin/features/debts/domain/entities/debt.dart';
import 'package:salin/features/debts/presentation/providers/debt_providers.dart';
import 'package:salin/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:salin/features/recurring/domain/entities/recurring_rule.dart';
import 'package:salin/features/recurring/domain/entities/recurring_instance.dart';
import 'package:salin/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:salin/features/splits/data/repositories/split_repository_impl.dart';
import 'package:salin/features/splits/domain/entities/split.dart';
import 'package:salin/features/splits/domain/entities/split_participant.dart';
import 'package:salin/features/splits/presentation/providers/split_providers.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/shared/enums/financial_enums.dart';

void main() {
  late AppDatabase database;
  late AccountRepositoryImpl accountRepository;
  late ContactRepositoryImpl contactRepository;
  late RecurringRepositoryImpl recurringRepository;
  late SplitRepositoryImpl splitRepository;
  late DebtRepositoryImpl debtRepository;
  late TransactionRepositoryImpl transactionRepository;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    accountRepository = AccountRepositoryImpl(database);
    contactRepository = ContactRepositoryImpl(database);
    recurringRepository = RecurringRepositoryImpl(database);
    splitRepository = SplitRepositoryImpl(database);
    debtRepository = DebtRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        contactRepositoryProvider.overrideWithValue(contactRepository),
        recurringRepositoryProvider.overrideWithValue(recurringRepository),
        splitRepositoryProvider.overrideWithValue(splitRepository),
        debtRepositoryProvider.overrideWithValue(debtRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  group('Salin Core Sprint 3 Subsystems Tests', () {
    test('Contact creation and retrieve', () async {
      final now = DateTime.now().toUtc();
      final contact = Contact(
        id: 'c_maria',
        name: 'Maria Clara',
        phone: '09171234567',
        email: 'maria@clara.com',
        notes: 'Roommate',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );

      await contactRepository.create(contact);
      final retrieved = await contactRepository.getById('c_maria');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Maria Clara');

      final all = await container.read(contactsListProvider.future);
      expect(all.length, 1);
    });

    test('Recurring Schedule rule handles initial instances and mark-paid flow', () async {
      final now = DateTime.now().toUtc();
      
      // Setup Account
      final account = Account(
        id: 'acc_wallet',
        name: 'Wallet',
        accountType: AccountType.cash,
        openingBalanceMinor: 1000000, // ₱10,000.00
        currency: 'PHP',
        icon: 'wallet',
        displayOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      // Create Rule (Monthly Subscription: ₱549.00 Netflix)
      final rule = RecurringRule(
        id: 'rr_netflix',
        title: 'Netflix Subscription',
        accountId: 'acc_wallet',
        categoryId: 'cat_entertainment',
        amountMinor: 54900,
        direction: MoneyDirection.outflow,
        frequency: RecurringFrequency.monthly,
        interval: 1,
        startDate: now.subtract(const Duration(days: 1)),
        autoGenerate: true,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );

      await recurringRepository.createRule(rule);

      // Verify that initial instances were generated (we generate 5 by default)
      final initialInstances = await container.read(upcomingInstancesListProvider.future);
      expect(initialInstances.length, 5);
      expect(initialInstances.first.status, RecurringInstanceStatus.pending);

      // Mark the first instance as paid
      final firstInstanceId = initialInstances.first.id;
      await recurringRepository.markAsPaid(firstInstanceId, 'acc_wallet', now);

      // Verify transaction was generated in ledger
      final entries = await container.read(ledgerEntriesListProvider.future);
      expect(entries.length, 1);
      expect(entries.first.amountMinor, 54900);
      expect(entries.first.direction, MoneyDirection.outflow);
      expect(entries.first.origin, LedgerOrigin.recurring);
      expect(entries.first.recurringInstanceId, firstInstanceId);

      // Verify that the marked instance status is updated to paid
      final allInstances = await database.select(database.recurringInstances).get();
      final paidInstance = allInstances.firstWhere((i) => i.id == firstInstanceId);
      expect(paidInstance.status, RecurringInstanceStatus.paid.index);
    });

    test('Split expense creation and repayment calculations', () async {
      final now = DateTime.now().toUtc();

      // 1. Create Contacts
      final cBob = Contact(
        id: 'c_bob',
        name: 'Bob',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await contactRepository.create(cBob);

      // 2. Create Split: ₱1,200 Dinner, Bob owes ₱400 (remaining split amount = ₱400)
      final split = Split(
        id: 's_dinner',
        title: 'Dinner splitting',
        totalMinor: 120000, // ₱1,200
        status: SplitStatus.active,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );

      final pBob = SplitParticipant(
        id: 'sp_bob',
        splitId: 's_dinner',
        contactId: 'c_bob',
        shareMinor: 40000, // ₱400
        createdAt: now,
        updatedAt: now,
      );

      // Setup account for the base transaction and repayment
      final account = Account(
        id: 'acc_1',
        name: 'Cash Wallet',
        accountType: AccountType.cash,
        openingBalanceMinor: 2000000,
        currency: 'PHP',
        icon: 'cash',
        displayOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      await splitRepository.createSplit(
        split,
        [pBob],
        accountId: 'acc_1',
        occurredAt: now,
      );

      // Verify base transaction (outflow ₱1,200)
      final ledger1 = await container.read(ledgerEntriesListProvider.future);
      expect(ledger1.length, 1);
      expect(ledger1.first.amountMinor, 120000);
      expect(ledger1.first.direction, MoneyDirection.outflow);

      // Verify outstanding balance
      final remaining = await splitRepository.getRemainingBalance('s_dinner');
      expect(remaining, 40000); // ₱400 expected from Bob

      // Receive Bob's repayment (₱400)
      await splitRepository.recordRepayment(
        's_dinner',
        'c_bob',
        'acc_1',
        40000,
        now,
        'Bob dinner share',
      );

      // Verify outstanding balance is 0 and status is settled
      final remainingAfter = await splitRepository.getRemainingBalance('s_dinner');
      expect(remainingAfter, 0);

      final splitAfter = await splitRepository.getById('s_dinner');
      expect(splitAfter!.status, SplitStatus.settled);

      // Verify that repayment ledger entry is added as inflow
      final ledger2 = await container.read(ledgerEntriesListProvider.future);
      expect(ledger2.length, 2);
      final repaymentEntry = ledger2.firstWhere((e) => e.origin == LedgerOrigin.splitSettlement);
      expect(repaymentEntry.direction, MoneyDirection.inflow);
      expect(repaymentEntry.amountMinor, 40000);
    });

    test('Lent Debt creation and repayment flow', () async {
      final now = DateTime.now().toUtc();

      // Create contact
      final cAlice = Contact(
        id: 'c_alice',
        name: 'Alice',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await contactRepository.create(cAlice);

      // Setup account
      final account = Account(
        id: 'acc_gcash',
        name: 'GCash',
        accountType: AccountType.eWallet,
        openingBalanceMinor: 500000, // ₱5,000.00
        currency: 'PHP',
        icon: 'wallet',
        displayOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await accountRepository.create(account);

      // Create Debt (Lent ₱1,500.00 to Alice)
      final debt = Debt(
        id: 'd_alice_loan',
        contactId: 'c_alice',
        isLent: true,
        principalMinor: 150000,
        status: DebtStatus.active,
        note: 'Alice borrowing for concert ticket',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );

      await debtRepository.createDebt(
        debt,
        isLent: true,
        accountId: 'acc_gcash',
        occurredAt: now,
      );

      // Verify lent debt displays as isLent = true
      final retrieved = await debtRepository.getById('d_alice_loan');
      expect(retrieved!.isLent, isTrue);
      expect(retrieved.note, 'Alice borrowing for concert ticket');

      // Verify origin ledger entry is outflow (₱1,500 cash went out when lent)
      final ledger = await container.read(ledgerEntriesListProvider.future);
      expect(ledger.length, 1);
      expect(ledger.first.direction, MoneyDirection.outflow);
      expect(ledger.first.amountMinor, 150000);

      // Record partial repayment of ₱500.00 (direction should be inflow)
      await debtRepository.recordRepayment(
        'd_alice_loan',
        'acc_gcash',
        50000,
        now,
        'Alice partial repayment',
      );

      // Verify remaining balance
      final remaining = await debtRepository.getRemainingBalance('d_alice_loan');
      expect(remaining, 100000); // ₱1,000 remaining

      // Verify the repayment ledger entry (inflow ₱500)
      final ledger2 = await container.read(ledgerEntriesListProvider.future);
      expect(ledger2.length, 2);
      final repaymentEntry = ledger2.firstWhere((e) => e.origin == LedgerOrigin.debtSettlement);
      expect(repaymentEntry.direction, MoneyDirection.inflow);
      expect(repaymentEntry.amountMinor, 50000);
    });
  });
}
