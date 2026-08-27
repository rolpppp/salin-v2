import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/presentation/providers/account_providers.dart';
import 'package:salin/features/onboarding/presentation/widgets/onboarding_page_four.dart';
import 'package:salin/features/onboarding/presentation/widgets/onboarding_page_one.dart';
import 'package:salin/features/onboarding/presentation/widgets/onboarding_page_three.dart';
import 'package:salin/features/onboarding/presentation/widgets/onboarding_page_two.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/domain/entities/ledger_entry.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/shared/enums/financial_enums.dart';

void main() {
  late AppDatabase database;
  late AccountRepositoryImpl accountRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() async {
    // A fresh AppDatabase seeds 'acc_default_cash' itself (see
    // database.dart's onCreate), matching what a real fresh install has —
    // no need to create it here.
    database = AppDatabase(NativeDatabase.memory());
    accountRepository = AccountRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        accountRepositoryProvider.overrideWithValue(accountRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );
  }

  group('Onboarding screens', () {
    testWidgets('Welcome screen renders and continue fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(OnboardingPageOne(onContinue: () => tapped = true)));

      expect(find.text("What's left?"), findsOneWidget);
      await tester.tap(find.text('START WITH A ROUGH ESTIMATE'));
      expect(tapped, isTrue);
    });

    testWidgets('Baseline screen writes the opening balance and reports it', (tester) async {
      int? reportedMinor;
      await tester.pumpWidget(wrap(OnboardingPageTwo(onContinue: (minor) => reportedMinor = minor)));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '10000');
      await tester.tap(find.text('THAT LOOKS RIGHT'));
      await tester.pumpAndSettle();

      final updated = await accountRepository.getById('acc_default_cash');
      expect(updated!.openingBalanceMinor, 1000000);
      expect(reportedMinor, 1000000);
    });

    testWidgets("Baseline screen's later option leaves balance untouched and reports 0", (tester) async {
      int? reportedMinor;
      await tester.pumpWidget(wrap(OnboardingPageTwo(onContinue: (minor) => reportedMinor = minor)));
      await tester.pump();

      await tester.tap(find.text("I'LL DO THIS LATER"));
      await tester.pump();

      final account = await accountRepository.getById('acc_default_cash');
      expect(account!.openingBalanceMinor, 0);
      expect(reportedMinor, 0);
    });

    testWidgets('Try it out screen parses input live and logs a real ledger entry', (tester) async {
      int? loggedAmount;
      String? loggedDescription;
      await tester.pumpWidget(wrap(OnboardingPageThree(
        onLogged: (amount, description) {
          loggedAmount = amount;
          loggedDescription = description;
        },
      )));
      await tester.pump();

      expect(find.text('WAITING FOR INPUT'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '150 jeepney fare');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('₱150.00'), findsOneWidget);
      expect(find.text('jeepney fare'), findsOneWidget);

      // Not pumpAndSettle: the button shows an indeterminate
      // CircularProgressIndicator while saving, which animates forever and
      // would make pumpAndSettle time out.
      await tester.tap(find.text('Log this expense'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(loggedAmount, 15000);
      expect(loggedDescription, 'jeepney fare');

      final entries = await transactionRepository.getAllLedgerEntries();
      expect(entries.length, 1);
      expect(entries.first.amountMinor, 15000);
      expect(entries.first.accountId, 'acc_default_cash');

      // Explicitly unmount before the test ends. This disposes the
      // StreamProvider watching the ledger, which cancels drift's
      // underlying QueryStream — drift's cleanup schedules its own
      // zero-duration Timer (StreamQueryStore.markAsClosed), which needs
      // one more pump to fire before flutter_test's end-of-test invariant
      // check (`!timersPending`) runs, or it flags it as still pending.
      await tester.pumpWidget(const SizedBox.shrink());
      // Duration.zero, not a bare pump() — the pending timer's delay is
      // itself Duration.zero, and FakeAsync only fires it once the fake
      // clock is explicitly told to advance, even by zero.
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
    });

    testWidgets('Final screen shows the real remaining balance and finishes', (tester) async {
      final account = await accountRepository.getById('acc_default_cash');
      await accountRepository.update(account!.copyWith(openingBalanceMinor: 1000000));
      // The widget trusts totalBalanceProvider (real DB state) over its
      // loggedAmountMinor/loggedDescription props, so this test creates a
      // matching real ledger entry rather than relying on the props alone
      // — otherwise it'd be asserting on a number the widget never actually
      // computes that way.
      await transactionRepository.createLedgerEntry(LedgerEntry(
        id: 'entry_jeepney',
        accountId: 'acc_default_cash',
        amountMinor: 15000,
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.quickAdd,
        occurredAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      ));

      var finished = false;
      await tester.pumpWidget(wrap(OnboardingPageFour(
        baselineMinor: 1000000,
        loggedAmountMinor: 15000,
        loggedDescription: 'jeepney fare',
        onFinish: () => finished = true,
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('₱9,850.00'), findsOneWidget);
      expect(find.text('₱10,000.00'), findsOneWidget);

      await tester.tap(find.text('Take me home'));
      expect(finished, isTrue);

      // See the identical comment in the "Try it out" test above — this
      // screen also watches StreamProviders, so it needs the same explicit
      // unmount-then-pump before ending.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'Final screen shows the correct baseline on its very first frame, '
      'before any account stream has had a chance to emit',
      (tester) async {
        // Regression test: baselineMinor used to be re-derived from
        // accountsListProvider.value inside build(), which can still be
        // null/empty on the first frame of a freshly mounted widget — this
        // asserts immediately after pumpWidget's single implicit frame,
        // with no extra settling pumps, to prove the Baseline row no longer
        // depends on that stream having emitted yet.
        await tester.pumpWidget(wrap(OnboardingPageFour(
          baselineMinor: 120000,
          loggedAmountMinor: null,
          loggedDescription: null,
          onFinish: () {},
        )));

        // Two matches, not one: with no logged expense, the hero
        // "Remaining Balance" and the "Baseline" row legitimately show the
        // same figure.
        expect(find.text('₱1,200.00'), findsNWidgets(2));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(Duration.zero);
        await tester.pump(Duration.zero);
      },
    );
  });
}
