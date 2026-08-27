import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/presentation/providers/account_providers.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/features/transactions/presentation/widgets/quick_add_view.dart';

// Covers docs/NEXT_ITERATION.md's Core Value Proposition revision (adopted
// 2026-08-26) at the UI level: Quick Add must auto-save a best-effort
// single line with an unambiguous amount exactly like a Confident match —
// no staging, no confirmation tap — while a line with genuinely ambiguous
// amount (more than one number) still stages and blocks confirmation.
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

  testWidgets('best-effort single line with an unambiguous amount auto-saves without staging', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    await tester.enterText(find.byType(TextField), 'Spent 150 on coffee');
    await drain(tester);
    await tester.tap(find.text('Parse'));
    await drain(tester);
    await flushConnectivityCheck(tester);

    // Never staged for review — auto-saved immediately, category shown for
    // transparency rather than gated behind a confirmation tap.
    expect(find.text('Parsed Transactions'), findsNothing);
    expect(find.textContaining('Saved ₱150.00'), findsOneWidget);
    expect(find.textContaining('(Food)'), findsOneWidget);
    expect(find.text('₱150.00 overdrawn'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('a line with more than one number stages for review and blocks Confirm All', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    await tester.enterText(find.byType(TextField), 'Owed 500 but paid back 150 for dinner');
    await drain(tester);
    await tester.tap(find.text('Parse'));
    await drain(tester);
    await flushConnectivityCheck(tester);

    expect(find.text('Parsed Transactions'), findsOneWidget);
    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(find.text('Confirm All (Review Needed)'), findsOneWidget);

    final confirmAllButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Confirm All (Review Needed)'));
    expect(confirmAllButton.onPressed, isNull);

    // Balance is untouched — nothing was saved while the ambiguous amount
    // is still blocking confirmation.
    expect(find.text('₱0.00 left'), findsOneWidget);

    await unmountAndFlush(tester);
  });
}
