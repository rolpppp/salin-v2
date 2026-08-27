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

// Covers backlog item 3 (docs/SPRINTS.md Sprint 7 / docs/UX_REVIEW.md
// Recommendation 2, docs/FRICTION_REPORT.md B2): one flagged line in a
// multi-transaction paste must no longer block confirming the rest of the
// batch. Confirm All should act only on the ready items, leaving the
// flagged one staged for individual resolution.
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

  testWidgets('Confirm All saves the ready item and leaves the flagged one staged, in a 2-line batch', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    // Two lines: one flagged (multiple numbers -> ambiguous amount), one
    // clean. Multi-line input always stages (never takes the single-item
    // auto-save fast path), so both land in the review queue together.
    await tester.enterText(
      find.byType(TextField),
      'Owed 500 but paid back 150 for dinner\nGrab 250',
    );
    await drain(tester);
    await tester.tap(find.text('Parse'));
    await drain(tester);
    await flushConnectivityCheck(tester);

    expect(find.text('Parsed Transactions'), findsOneWidget);
    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(find.text('CONFIDENT'), findsOneWidget);

    final confirmButtonFinder = find.widgetWithText(ElevatedButton, 'Confirm 1 Ready');
    expect(confirmButtonFinder, findsOneWidget);
    final confirmButton = tester.widget<ElevatedButton>(confirmButtonFinder);
    expect(confirmButton.onPressed, isNotNull);

    await tester.ensureVisible(confirmButtonFinder);
    await drain(tester, times: 2);
    await tester.tap(confirmButtonFinder);
    await drain(tester);

    // The confident item was saved and removed from the queue; the flagged
    // one is still staged, waiting for individual resolution.
    expect(find.text('Parsed Transactions'), findsOneWidget);
    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(find.text('CONFIDENT'), findsNothing);
    expect(find.text('₱250.00 overdrawn'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('Confirm All (Review Needed) stays disabled when every item is flagged', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    await tester.enterText(
      find.byType(TextField),
      'Owed 500 but paid back 150 for dinner\nOwed 300 but only had 100 for gas',
    );
    await drain(tester);
    await tester.tap(find.text('Parse'));
    await drain(tester);
    await flushConnectivityCheck(tester);

    final confirmButtonFinder = find.widgetWithText(ElevatedButton, 'Confirm All (Review Needed)');
    expect(confirmButtonFinder, findsOneWidget);
    final confirmButton = tester.widget<ElevatedButton>(confirmButtonFinder);
    expect(confirmButton.onPressed, isNull);

    await unmountAndFlush(tester);
  });
}
