import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salin/core/config/welcome_back_config.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:salin/features/accounts/domain/balance_adjustment.dart';
import 'package:salin/features/accounts/domain/entities/account.dart';
import 'package:salin/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:salin/features/transactions/domain/entities/ledger_entry.dart';
import 'package:salin/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:salin/shared/enums/financial_enums.dart';

void main() {
  group('planBalanceAdjustment', () {
    test('real below computed is an outflow of the difference', () {
      final plan = planBalanceAdjustment(accountId: 'a', computedMinor: 500000, realMinor: 184000);
      expect(plan, const BalanceAdjustment(accountId: 'a', direction: MoneyDirection.outflow, amountMinor: 316000));
    });

    test('real above computed is an inflow of the difference', () {
      final plan = planBalanceAdjustment(accountId: 'a', computedMinor: 100, realMinor: 350);
      expect(plan!.direction, MoneyDirection.inflow);
      expect(plan.amountMinor, 250);
    });

    test('equal balances write nothing', () {
      expect(planBalanceAdjustment(accountId: 'a', computedMinor: 1234, realMinor: 1234), isNull);
    });

    test('works across zero (negative balances)', () {
      final plan = planBalanceAdjustment(accountId: 'a', computedMinor: -500, realMinor: 700);
      expect(plan!.direction, MoneyDirection.inflow);
      expect(plan.amountMinor, 1200);
    });
  });

  group('parseCentavos', () {
    test('parses exactly, with no floating point drift', () {
      expect(parseCentavos('1234.50'), 123450);
      expect(parseCentavos('0.10'), 10);
      expect(parseCentavos('0.29'), 29); // 0.29 * 100 == 28.999... in doubles
      expect(parseCentavos('19.99'), 1999);
      expect(parseCentavos('1,234.5'), 123450);
      expect(parseCentavos('5000'), 500000);
      expect(parseCentavos('.5'), 50);
      expect(parseCentavos('12.'), 1200);
      expect(parseCentavos('  ₱3,160 '), 316000);
      expect(parseCentavos('90071992547409.93'), 9007199254740993);
    });

    test('handles signs', () {
      expect(parseCentavos('-3160.00'), -316000);
      expect(parseCentavos('−3160'), -316000);
      expect(parseCentavos('+5'), 500);
      expect(parseCentavos('0'), 0);
    });

    test('rejects empty, malformed and over-precise input', () {
      expect(parseCentavos(''), isNull);
      expect(parseCentavos('abc'), isNull);
      expect(parseCentavos('1.234'), isNull);
      expect(parseCentavos('1..2'), isNull);
      expect(parseCentavos('.'), isNull);
      expect(parseCentavos('1,23'), isNull);
    });

    test('round-trips through minorToInputText', () {
      for (final v in [0, 5, 50, 123450, -316000, -1]) {
        expect(parseCentavos(minorToInputText(v)), v);
      }
    });
  });

  group('formatMinor', () {
    test('formats signed differences', () {
      expect(formatMinor(-316000, showSign: true), '−₱3,160');
      expect(formatMinor(12050, showSign: true), '+₱120.50');
      expect(formatMinor(500000), '₱5,000');
      expect(formatMinor(100000000), '₱1,000,000');
    });

    test('uses the account currency', () {
      expect(formatMinor(1234, currency: 'USD'), r'$12.34');
      expect(formatMinor(1000, currency: 'CHF'), 'CHF 10');
    });
  });

  group('welcome-back check', () {
    final now = DateTime.utc(2026, 10, 12, 9);

    test('13 days away does not trigger', () {
      expect(WelcomeBackConfig.daysAwayIfDue(now.subtract(const Duration(days: 13, hours: 23)), now), isNull);
    });

    test('14 days away triggers', () {
      expect(WelcomeBackConfig.daysAwayIfDue(now.subtract(const Duration(days: 14)), now), 14);
      expect(WelcomeBackConfig.daysAwayIfDue(now.subtract(const Duration(days: 30)), now), 30);
    });

    test('threshold lives in one constant', () {
      expect(kWelcomeBackThresholdDays, 14);
    });

    test('first run (nothing stored) does not trigger, and stamps the time', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(await WelcomeBackConfig.recordOpen(prefs, now), isNull);
      expect(prefs.getInt(WelcomeBackConfig.lastOpenedKey), now.millisecondsSinceEpoch);
    });

    test('recordOpen reports days away and always updates the timestamp', () async {
      final old = now.subtract(const Duration(days: 20));
      SharedPreferences.setMockInitialValues({WelcomeBackConfig.lastOpenedKey: old.millisecondsSinceEpoch});
      final prefs = await SharedPreferences.getInstance();
      expect(await WelcomeBackConfig.recordOpen(prefs, now), 20);
      expect(prefs.getInt(WelcomeBackConfig.lastOpenedKey), now.millisecondsSinceEpoch);
      // Immediately reopening is not "away".
      expect(await WelcomeBackConfig.recordOpen(prefs, now.add(const Duration(minutes: 1))), isNull);
    });
  });

  group('applyBalanceAdjustments (repository)', () {
    late AppDatabase db;
    late AccountRepositoryImpl accounts;
    late TransactionRepositoryImpl repo;

    Account account(String id, int opening, {String currency = 'PHP'}) {
      final now = DateTime.now().toUtc();
      return Account(
        id: id,
        name: id,
        accountType: AccountType.bank,
        openingBalanceMinor: opening,
        currency: currency,
        icon: 'x',
        displayOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
    }

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      accounts = AccountRepositoryImpl(db);
      repo = TransactionRepositoryImpl(db);
      await accounts.create(account('gcash', 500000));
      await accounts.create(account('bank', 100000));
      await accounts.create(account('cash', 20000));
      final now = DateTime.now().toUtc();
      await repo.createLedgerEntry(LedgerEntry(
        id: 'spend',
        accountId: 'gcash',
        categoryId: 'cat_food',
        amountMinor: 30000,
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.manual,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ));
    });

    tearDown(() => db.close());

    test('writes one correctly shaped entry per changed account, none for unchanged', () async {
      // gcash computed = 5000 - 300 = 4700 ; real 1540 -> outflow 3160.
      // bank computed 1000 ; real 1000.50 -> inflow 0.50.
      // cash computed 200 ; real 200 -> nothing.
      final written = await repo.applyBalanceAdjustments({
        'gcash': 154000,
        'bank': 100050,
        'cash': 20000,
      });
      expect(written, hasLength(2));

      final rows = await (db.select(db.ledgerEntries)
            ..where((t) => t.origin.equals(LedgerOrigin.adjustment.index)))
          .get();
      expect(rows, hasLength(2));

      final g = rows.firstWhere((r) => r.accountId == 'gcash');
      expect(g.direction, MoneyDirection.outflow.index);
      expect(g.amountMinor, 316000);
      expect(g.categoryId, isNull);
      expect(g.transferId, isNull);
      expect(g.recurringInstanceId, isNull);
      expect(g.debtId, isNull);
      expect(g.splitId, isNull);
      expect(g.note, 'Balance adjustment');
      expect(g.deletedAt, isNull);
      expect(g.syncStatus, SyncStatus.localOnly.index);
      expect(g.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(g.createdAt, g.updatedAt);
      expect(g.occurredAt, g.createdAt);
      expect(DateTime.now().toUtc().millisecondsSinceEpoch - g.occurredAt, lessThan(10000));

      final b = rows.firstWhere((r) => r.accountId == 'bank');
      expect(b.direction, MoneyDirection.inflow.index);
      expect(b.amountMinor, 50);
    });

    test('balances show the real amounts afterwards; opening balances and history untouched', () async {
      await repo.applyBalanceAdjustments({'gcash': 154000, 'bank': 100050});
      expect(await accounts.watchBalance('gcash').first, 154000);
      expect(await accounts.watchBalance('bank').first, 100050);
      expect(await accounts.watchBalance('cash').first, 20000);

      expect((await accounts.getById('gcash'))!.openingBalanceMinor, 500000);
      final spend = await repo.getLedgerEntryById('spend');
      expect(spend, isNotNull);
      expect(spend!.amountMinor, 30000);
      expect(spend.deletedAt, isNull);
    });

    test('running it twice with the same real balances is a no-op the second time', () async {
      await repo.applyBalanceAdjustments({'gcash': 154000});
      final second = await repo.applyBalanceAdjustments({'gcash': 154000});
      expect(second, isEmpty);
    });

    test('is atomic: a failure part-way writes nothing', () async {
      // Make the second insert fail by dropping the table after the first
      // account is processed is awkward; instead trigger a constraint failure
      // with a trigger on the second account.
      await db.customStatement('''
        CREATE TRIGGER fail_bank BEFORE INSERT ON ledger_entries
        WHEN NEW.account_id = 'bank'
        BEGIN SELECT RAISE(ABORT, 'boom'); END;
      ''');
      await expectLater(
        repo.applyBalanceAdjustments({'gcash': 154000, 'bank': 100050}),
        throwsA(anything),
      );
      final rows = await (db.select(db.ledgerEntries)
            ..where((t) => t.origin.equals(LedgerOrigin.adjustment.index)))
          .get();
      expect(rows, isEmpty);
    });

    test('unknown accounts are ignored', () async {
      expect(await repo.applyBalanceAdjustments({'nope': 5}), isEmpty);
    });
  });

  group('stats exclusion', () {
    test('reportableEntries drops adjustments but keeps everything else', () {
      final now = DateTime.now().toUtc();
      LedgerEntry e(String id, LedgerOrigin o, MoneyDirection d) => LedgerEntry(
            id: id,
            accountId: 'a',
            amountMinor: 100,
            direction: d,
            origin: o,
            occurredAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.localOnly,
          );
      final out = reportableEntries([
        e('1', LedgerOrigin.manual, MoneyDirection.outflow),
        e('2', LedgerOrigin.adjustment, MoneyDirection.outflow),
        e('3', LedgerOrigin.adjustment, MoneyDirection.inflow),
        e('4', LedgerOrigin.quickAdd, MoneyDirection.inflow),
      ]);
      expect(out.map((x) => x.id), ['1', '4']);
    });

    test('reportable provider excludes adjustments while balances still include them', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final accounts = AccountRepositoryImpl(db);
      final repo = TransactionRepositoryImpl(db);
      final now = DateTime.now().toUtc();
      await accounts.create(Account(
        id: 'a',
        name: 'A',
        accountType: AccountType.cash,
        openingBalanceMinor: 100000,
        currency: 'PHP',
        icon: 'x',
        displayOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      ));
      await repo.createLedgerEntry(LedgerEntry(
        id: 'real',
        accountId: 'a',
        amountMinor: 1000,
        direction: MoneyDirection.outflow,
        origin: LedgerOrigin.manual,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      ));
      await repo.applyBalanceAdjustments({'a': 50000});

      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        transactionRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final sub = container.listen(ledgerEntriesListProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(ledgerEntriesListProvider.future);

      final all = container.read(ledgerEntriesListProvider).value!;
      final reportable = container.read(reportableLedgerEntriesProvider).value!;
      expect(all, hasLength(2));
      expect(reportable.map((e) => e.id), ['real']);
      expect(await accounts.watchBalance('a').first, 50000);
    });
  });
}
