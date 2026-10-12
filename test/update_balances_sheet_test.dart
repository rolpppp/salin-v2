import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salin/core/config/onboarding_config.dart';
import 'package:salin/core/config/welcome_back_config.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/core/services/sync/sync_providers.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/domain/entities/account.dart';
import 'package:salin/features/accounts/presentation/pages/accounts_page.dart';
import 'package:salin/features/accounts/presentation/providers/account_providers.dart';
import 'package:salin/features/accounts/presentation/widgets/update_balances_sheet.dart';
import 'package:salin/features/accounts/presentation/widgets/welcome_back_gate.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/shared/enums/financial_enums.dart';

void main() {
  late AppDatabase database;
  late AccountRepositoryImpl accountRepository;
  late TransactionRepositoryImpl transactionRepository;

  Account account(String id, String name, int opening, int order,
      {String currency = 'PHP', bool archived = false}) {
    final now = DateTime.now().toUtc();
    return Account(
      id: id,
      name: name,
      accountType: AccountType.bank,
      openingBalanceMinor: opening,
      currency: currency,
      icon: 'x',
      displayOrder: order,
      isArchived: archived,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.localOnly,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    accountRepository = AccountRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);
    // Seeded 'Cash' (displayOrder 0) exists already; keep it out of the way.
    await accountRepository.archive('acc_default_cash', isArchived: true);
    await accountRepository.create(account('gcash', 'GCash', 500000, 1));
    await accountRepository.create(account('bank', 'BDO', 120000, 2));
    await accountRepository.create(account('usd', 'USD Wallet', 25000, 3, currency: 'USD'));
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Drift transactions need real async turns, which FakeAsync won't give.
  Future<void> realWait(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
  }

  List<Override> overrides() => [
        databaseProvider.overrideWithValue(database),
        accountRepositoryProvider.overrideWithValue(accountRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ];

  Widget sheetApp({int? daysAway}) => ProviderScope(
        overrides: overrides(),
        child: MaterialApp(home: Scaffold(body: UpdateBalancesSheet(daysAway: daysAway))),
      );

  Future<List<LedgerEntryRow>> adjustments() => (database.select(database.ledgerEntries)
        ..where((t) => t.origin.equals(LedgerOrigin.adjustment.index)))
      .get();

  testWidgets('prefills each active account with what Salin says, in its own currency', (tester) async {
    await tester.pumpWidget(sheetApp());
    await settle(tester);

    expect(find.text('Salin says ₱5,000'), findsOneWidget);
    expect(find.text('Salin says ₱1,200'), findsOneWidget);
    expect(find.text(r'Salin says $250'), findsOneWidget);
    // Archived Cash is not listed.
    expect(find.text('Cash'), findsNothing);
    expect(find.widgetWithText(TextField, '5000.00'), findsOneWidget);
    expect(find.widgetWithText(TextField, '250.00'), findsOneWidget);
    // Manual entry point: no welcome line.
    expect(find.textContaining('Welcome back'), findsNothing);
    // Nothing changed yet.
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await unmount(tester);
  });

  testWidgets('shows the welcome-back line and a Skip button when opened by the prompt', (tester) async {
    await tester.pumpWidget(sheetApp(daysAway: 21));
    await settle(tester);
    expect(find.text("Welcome back! It's been 21 days."), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('shows the live difference and the summary as the user types', (tester) async {
    await tester.pumpWidget(sheetApp());
    await settle(tester);

    await tester.enterText(find.byKey(const Key('real_gcash')), '1840');
    await tester.pump();
    expect(find.text('Difference −₱3,160'), findsOneWidget);
    expect(find.text('1 account will be corrected; recorded as Balance adjustment, history kept.'),
        findsOneWidget);

    await tester.enterText(find.byKey(const Key('real_bank')), '1,300.50');
    await tester.pump();
    expect(find.text('Difference +₱100.50'), findsOneWidget);
    expect(find.text('2 accounts will be corrected; recorded as Balance adjustment, history kept.'),
        findsOneWidget);

    // Typing the original value back means no change for that account.
    await tester.enterText(find.byKey(const Key('real_bank')), '1200');
    await tester.pump();
    expect(find.text('No change'), findsNWidgets(2)); // BDO and USD Wallet
    expect(find.textContaining('1 account will be corrected'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('invalid input blocks saving', (tester) async {
    await tester.pumpWidget(sheetApp());
    await settle(tester);
    await tester.enterText(find.byKey(const Key('real_gcash')), '12.345');
    await tester.pump();
    expect(find.text('Enter an amount like 1,250.50'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await unmount(tester);
  });

  testWidgets('fields are labelled for screen readers', (tester) async {
    await tester.pumpWidget(sheetApp());
    await settle(tester);
    final field = tester.widget<TextField>(find.byKey(const Key('real_gcash')));
    expect(field.decoration!.labelText, 'Real balance, GCash (PHP)');
    await unmount(tester);
  });

  testWidgets('Update balances writes one adjustment per changed account and balances follow', (tester) async {
    await tester.pumpWidget(sheetApp());
    await settle(tester);

    await tester.enterText(find.byKey(const Key('real_gcash')), '1840');
    await tester.enterText(find.byKey(const Key('real_usd')), '260.50');
    await tester.pump();
    await tester.tap(find.text('Update balances').last);
    await realWait(tester);

    final rows = (await tester.runAsync(adjustments))!;
    expect(rows, hasLength(2));
    final g = rows.firstWhere((r) => r.accountId == 'gcash');
    expect(g.direction, MoneyDirection.outflow.index);
    expect(g.amountMinor, 316000);
    final u = rows.firstWhere((r) => r.accountId == 'usd');
    expect(u.direction, MoneyDirection.inflow.index);
    expect(u.amountMinor, 1050);
    expect(rows.any((r) => r.accountId == 'bank'), isFalse);

    expect(await tester.runAsync(() => accountRepository.watchBalance('gcash').first), 184000);
    expect(await tester.runAsync(() => accountRepository.watchBalance('usd').first), 26050);

    await unmount(tester);
  });

  testWidgets('Skip writes nothing and closes the sheet', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showUpdateBalancesSheet(context, daysAway: 15),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.text("Welcome back! It's been 15 days."), findsOneWidget);

    await tester.enterText(find.byKey(const Key('real_gcash')), '1');
    await tester.pump();
    await tester.tap(find.text('Skip'));
    await realWait(tester);

    expect(find.text("Welcome back! It's been 15 days."), findsNothing);
    expect(await tester.runAsync(adjustments), isEmpty);
    await unmount(tester);
  });

  testWidgets('Accounts screen has an Update balances action that opens the form', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: const MaterialApp(home: AccountsPage()),
    ));
    await settle(tester);

    final button = find.byKey(const Key('update_balances_button'));
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await settle(tester);

    expect(find.text('Salin says ₱5,000'), findsOneWidget);
    expect(find.textContaining('Welcome back'), findsNothing);
    await unmount(tester);
  });

  group('WelcomeBackGate', () {
    final navKey = GlobalKey<NavigatorState>();
    final now = DateTime.utc(2026, 10, 12, 9);

    Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferences.getInstance();
    }

    Widget gateApp(SharedPreferences prefs) => ProviderScope(
          overrides: [
            ...overrides(),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            home: const Scaffold(body: Text('home')),
            builder: (context, child) =>
                WelcomeBackGate(navigatorKey: navKey, now: () => now, child: child!),
          ),
        );

    final away20 = now.subtract(const Duration(days: 20)).millisecondsSinceEpoch;

    testWidgets('shows the prompt after 14+ days away for an onboarded user with accounts', (tester) async {
      final prefs = await prefsWith({
        WelcomeBackConfig.lastOpenedKey: away20,
        OnboardingConfig.completedKey: true,
      });
      await tester.pumpWidget(gateApp(prefs));
      await settle(tester);
      expect(find.text("Welcome back! It's been 20 days."), findsOneWidget);
      expect(prefs.getInt(WelcomeBackConfig.lastOpenedKey), now.millisecondsSinceEpoch);
      await unmount(tester);
    });

    testWidgets('does not show for a fresh install, but stamps the open time', (tester) async {
      final prefs = await prefsWith({OnboardingConfig.completedKey: true});
      await tester.pumpWidget(gateApp(prefs));
      await settle(tester);
      expect(find.textContaining('Welcome back'), findsNothing);
      expect(prefs.getInt(WelcomeBackConfig.lastOpenedKey), now.millisecondsSinceEpoch);
      await unmount(tester);
    });

    testWidgets('does not show when away only 13 days', (tester) async {
      final prefs = await prefsWith({
        WelcomeBackConfig.lastOpenedKey: now.subtract(const Duration(days: 13)).millisecondsSinceEpoch,
        OnboardingConfig.completedKey: true,
      });
      await tester.pumpWidget(gateApp(prefs));
      await settle(tester);
      expect(find.textContaining('Welcome back'), findsNothing);
      await unmount(tester);
    });

    testWidgets('does not show before onboarding is finished', (tester) async {
      final prefs = await prefsWith({WelcomeBackConfig.lastOpenedKey: away20});
      await tester.pumpWidget(gateApp(prefs));
      await settle(tester);
      expect(find.textContaining('Welcome back'), findsNothing);
      expect(prefs.getInt(WelcomeBackConfig.lastOpenedKey), now.millisecondsSinceEpoch);
      await unmount(tester);
    });

    testWidgets('does not show when there are no active accounts', (tester) async {
      await accountRepository.archive('gcash', isArchived: true);
      await accountRepository.archive('bank', isArchived: true);
      await accountRepository.archive('usd', isArchived: true);
      final prefs = await prefsWith({
        WelcomeBackConfig.lastOpenedKey: away20,
        OnboardingConfig.completedKey: true,
      });
      await tester.pumpWidget(gateApp(prefs));
      await settle(tester);
      expect(find.textContaining('Welcome back'), findsNothing);
      await unmount(tester);
    });
  });
}
