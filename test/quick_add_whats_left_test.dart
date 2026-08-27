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

// Covers docs/NEXT_ITERATION.md's "inline what's left feedback" adoption:
// Quick Add must show the account's remaining balance in the same
// interaction as capture, updating live off the same providers the save
// path writes through — not only after navigating to Home.
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

    // AIService's first step always probes the native on-device AI channel
    // (see core/ai/local_ai_service.dart). With no handler registered,
    // TestDefaultBinaryMessengerBinding's default "no plugin" reply never
    // arrives within a FakeAsync testWidgets zone, hanging the await
    // indefinitely. Answer it directly so parsing proceeds immediately, the
    // same as a real device with no on-device model available.
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

  // Repeatedly pumps short durations to drain whatever multi-hop async
  // chain is in flight (provider reads, drift writes, stream re-emission)
  // without needing to know its exact microtask/Timer shape up front.
  Future<void> drain(WidgetTester tester, {int times = 10}) async {
    for (var i = 0; i < times; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  // QuickAddView.initState (and _handleParse, after a successful save) fire
  // a real InternetAddress.lookup() wrapped in .timeout(600ms) to detect
  // offline mode. Under flutter_test's FakeAsync zone that timer only fires
  // once the fake clock is explicitly advanced past it.
  Future<void> flushConnectivityCheck(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 700));
    await drain(tester, times: 3);
  }

  // Drift's stream-query cleanup on dispose schedules its own zero-duration
  // Timer (StreamQueryStore.markAsClosed) — unmount the tree and flush it
  // before the test ends, or flutter_test's `!timersPending` check fails.
  Future<void> unmountAndFlush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
  }

  testWidgets('shows the default account balance inline before any capture', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('₱0.00 left'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('auto-save of a confident single line updates the inline balance immediately, without navigation', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    await tester.enterText(find.byType(TextField), 'Lunch 180');
    await drain(tester);
    await tester.tap(find.text('Parse'));
    await drain(tester);
    await flushConnectivityCheck(tester); // _handleParse re-checks connectivity after saving

    // ₱180 expense against a ₱0 opening balance overdraws the account —
    // the banner must reflect that in the same screen, right away.
    expect(find.text('₱180.00 overdrawn'), findsOneWidget);
    expect(find.text('₱0.00 left'), findsNothing);

    await unmountAndFlush(tester);
  });

  testWidgets('auto-save of confident income increases the inline balance immediately', (tester) async {
    await tester.pumpWidget(wrap());
    await drain(tester);
    await flushConnectivityCheck(tester);

    await tester.enterText(find.byType(TextField), 'Salary 12000');
    await drain(tester);
    await tester.tap(find.text('Parse'));
    await drain(tester);
    await flushConnectivityCheck(tester);

    expect(find.text('₱12000.00 left'), findsOneWidget);

    await unmountAndFlush(tester);
  });
}
