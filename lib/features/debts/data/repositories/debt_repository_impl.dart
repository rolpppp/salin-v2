import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/tables/tables.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';

class DebtRepositoryImpl implements DebtRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DebtRepositoryImpl(this._db);

  // Mappers
  Debt _mapRowToDomain(DebtRow row) {
    final hasLentPrefix = row.note?.startsWith('[LENT] ') ?? true;
    final hasBorrowedPrefix = row.note?.startsWith('[BORROWED] ') ?? false;
    final isLent = hasLentPrefix && !hasBorrowedPrefix;

    String? noteText;
    if (row.note != null) {
      if (row.note!.startsWith('[LENT] ')) {
        noteText = row.note!.replaceFirst('[LENT] ', '');
      } else if (row.note!.startsWith('[BORROWED] ')) {
        noteText = row.note!.replaceFirst('[BORROWED] ', '');
      } else {
        noteText = row.note;
      }
      if (noteText != null && noteText.isEmpty) {
        noteText = null;
      }
    }

    return Debt(
      id: row.id,
      contactId: row.contactId,
      isLent: isLent,
      originLedgerEntryId: row.originLedgerEntryId,
      principalMinor: row.principalMinor,
      dueDate: row.dueDate != null ? DateTime.fromMillisecondsSinceEpoch(row.dueDate!, isUtc: true) : null,
      status: DebtStatus.values[row.status],
      note: noteText,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true) : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  DebtsCompanion _mapDomainToCompanion(Debt domain) {
    final prefix = domain.isLent ? '[LENT] ' : '[BORROWED] ';
    final noteWithPrefix = '$prefix${domain.note ?? ""}';

    return DebtsCompanion(
      id: Value(domain.id),
      contactId: Value(domain.contactId),
      originLedgerEntryId: Value(domain.originLedgerEntryId),
      principalMinor: Value(domain.principalMinor),
      dueDate: Value(domain.dueDate?.millisecondsSinceEpoch),
      status: Value(domain.status.index),
      note: Value(noteWithPrefix),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  @override
  Future<void> createDebt(
    Debt debt, {
    bool isLent = true,
    String? accountId,
    DateTime? occurredAt,
  }) async {
    await _db.transaction(() async {
      String? originId = debt.originLedgerEntryId;

      if (accountId != null && occurredAt != null) {
        originId = _uuid.v4();
        // Create base transaction
        final entry = LedgerEntriesCompanion(
          id: Value(originId),
          accountId: Value(accountId),
          categoryId: const Value(null),
          amountMinor: Value(debt.principalMinor),
          direction: Value(isLent ? MoneyDirection.outflow.index : MoneyDirection.inflow.index),
          origin: Value(LedgerOrigin.manual.index),
          occurredAt: Value(occurredAt.millisecondsSinceEpoch),
          note: Value(isLent ? 'Lent money' : 'Borrowed money'),
          createdAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          syncStatus: Value(SyncStatus.localOnly.index),
        );
        await _db.into(_db.ledgerEntries).insert(entry);
      }

      final updatedDebt = debt.copyWith(
        isLent: isLent,
        originLedgerEntryId: originId,
      );

      await _db.into(_db.debts).insert(_mapDomainToCompanion(updatedDebt));
    });
  }

  @override
  Future<void> deleteDebt(String debtId) async {
    await _db.transaction(() async {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.debts)..where((t) => t.id.equals(debtId))).write(
        DebtsCompanion(
          deletedAt: Value(nowMs),
          syncStatus: Value(SyncStatus.pendingUpload.index),
        ),
      );
    });
  }

  @override
  Future<void> recordRepayment(
    String debtId,
    String accountId,
    int amountMinor,
    DateTime occurredAt,
    String? note,
  ) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final debtRow = await (_db.select(_db.debts)..where((t) => t.id.equals(debtId))).getSingle();
      final debt = _mapRowToDomain(debtRow);

      // Repayment direction is opposite to debt setup:
      // - If we lent money (isLent = true), receiving repayment is inflow (income).
      // - If we borrowed money (isLent = false), making repayment is outflow (expense).
      final direction = debt.isLent ? MoneyDirection.inflow : MoneyDirection.outflow;

      final entryId = _uuid.v4();

      final entry = LedgerEntriesCompanion(
        id: Value(entryId),
        accountId: Value(accountId),
        debtId: Value(debtId),
        amountMinor: Value(amountMinor),
        direction: Value(direction.index),
        origin: Value(LedgerOrigin.debtSettlement.index),
        occurredAt: Value(occurredAt.millisecondsSinceEpoch),
        note: Value(note ?? (debt.isLent ? 'Repayment received' : 'Repayment paid')),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.localOnly.index),
      );
      await _db.into(_db.ledgerEntries).insert(entry);

      // Recalculate remaining balance
      final remaining = await getRemainingBalance(debtId);
      if (remaining <= 0) {
        await (_db.update(_db.debts)..where((t) => t.id.equals(debtId))).write(
          DebtsCompanion(
            status: Value(DebtStatus.paid.index),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    });
  }

  @override
  Future<Debt?> getById(String id) async {
    final query = _db.select(_db.debts)..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapRowToDomain(row) : null;
  }

  @override
  Future<List<Debt>> getAll() async {
    final query = _db.select(_db.debts)..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRowToDomain).toList();
  }

  @override
  Stream<List<Debt>> watchAllActive() {
    final query = _db.select(_db.debts)..where((t) => t.status.equals(DebtStatus.active.index) & t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRowToDomain).toList());
  }

  @override
  Stream<List<Debt>> watchAllSettled() {
    final query = _db.select(_db.debts)..where((t) => t.status.equals(DebtStatus.paid.index) & t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRowToDomain).toList());
  }

  @override
  Future<int> getRemainingBalance(String debtId) async {
    final debtRow = await (_db.select(_db.debts)..where((t) => t.id.equals(debtId))).getSingleOrNull();
    if (debtRow == null) return 0;

    final debt = _mapRowToDomain(debtRow);

    // Get all repayments
    // Repayment direction matches the opposite of debt creation:
    // - If lent: repayments are inflows
    // - If borrowed: repayments are outflows
    final direction = debt.isLent ? MoneyDirection.inflow : MoneyDirection.outflow;

    final ledgerQuery = _db.select(_db.ledgerEntries)
      ..where((t) => t.debtId.equals(debtId) & t.direction.equals(direction.index) & t.deletedAt.isNull());
    final repayments = await ledgerQuery.get();
    final totalRepaid = repayments.fold<int>(0, (sum, r) => sum + r.amountMinor);

    return debt.principalMinor - totalRepaid;
  }
}
