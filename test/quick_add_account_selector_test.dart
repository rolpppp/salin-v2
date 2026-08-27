import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/domain/entities/account.dart';
import 'package:salin/features/accounts/presentation/providers/account_providers.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/features/transactions/presentation/widgets/quick_add_view.dart';
import 'package:salin/shared/enums/financial_enums.dart';

// Covers backlog item 5 (docs/SPRINTS.md Sprint 7): Quick Add must let the
// user choose which account a capture saves into, instead of silently
// defaulting to whichever account happens to be first ("Cash").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late AppDatabase database;
  late AccountRepositoryImpl accountRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    accountRepository = AccountRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('app.salin/local_ai'),
      (call) async => false,
    );

    final now = DateTime.now().toUtc();
    await accountRepository.create(Account(
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
    ));
  });

  tearDown(() async {
    await database.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        accountRepositoryProvider.overrideWithValue(accountRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
      child: const MaterialApp(home: Scaffold(body: QuickAddView())),
    );
  }

  Future<void> drain(WidgetTester tester, {int times = 10}) async {
    for (var i = 0; i < times; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> flushConnectivityCheck(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 700));
    await drain(tester, times: 3);
  }

  Future<void> unmountAndFlush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
  }

  testWidgets('defaults to the first account and lets the user switch to another via a picker', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    // Defaults to Cash (seeded first, displayOrder 0).
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('₱0.00 left'), findsOneWidget);

    await tester.tap(find.text('Cash'));
    await drain(tester);

    expect(find.text('Save to'), findsOneWidget);
    expect(find.text('GCash'), findsOneWidget);

    await tester.tap(find.text('GCash').last);
    await drain(tester);

    expect(find.text('GCash'), findsOneWidget);
    expect(find.text('₱5000.00 left'), findsOneWidget);
    expect(find.text('Cash'), findsNothing);

    await unmountAndFlush(tester);
  });

  testWidgets('a confident auto-save goes to the switched-to account, not the original default', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    await tester.tap(find.text('Cash'));
    await drain(tester);
    await tester.tap(find.text('GCash').last);
    await drain(tester);

    await tester.enterText(find.byType(TextField), 'Lunch 180');
    await drain(tester);
    await tester.tap(find.text('Parse'));
    await drain(tester);
    await flushConnectivityCheck(tester);

    expect(find.textContaining('→ GCash'), findsOneWidget);
    expect(find.text('₱4820.00 left'), findsOneWidget); // 5000 - 180

    // A one-shot query, not another watch-stream subscription — avoids
    // adding a second drift stream to unwind alongside the widget tree's
    // own accountBalanceProvider watch during teardown below.
    final entries = await transactionRepository.getAllLedgerEntries();
    expect(entries, hasLength(1));
    expect(entries.single.accountId, 'acc_gcash');

    await unmountAndFlush(tester);
  });
}
