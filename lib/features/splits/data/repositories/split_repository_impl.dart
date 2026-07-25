import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/tables/tables.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/entities/split.dart';
import '../../domain/entities/split_participant.dart';
import '../../domain/repositories/split_repository.dart';

class SplitRepositoryImpl implements SplitRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  SplitRepositoryImpl(this._db);

  // Mappers
  Split _mapSplitRowToDomain(SplitRow row) {
    return Split(
      id: row.id,
      title: row.title,
      originLedgerEntryId: row.originLedgerEntryId,
      totalMinor: row.totalMinor,
      status: SplitStatus.values[row.status],
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true) : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  SplitsCompanion _mapSplitDomainToCompanion(Split domain) {
    return SplitsCompanion(
      id: Value(domain.id),
      title: Value(domain.title),
      originLedgerEntryId: Value(domain.originLedgerEntryId),
      totalMinor: Value(domain.totalMinor),
      status: Value(domain.status.index),
      note: Value(domain.note),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  SplitParticipant _mapParticipantRowToDomain(SplitParticipantRow row) {
    return SplitParticipant(
      id: row.id,
      splitId: row.splitId,
      contactId: row.contactId,
      shareMinor: row.shareMinor,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  SplitParticipantsCompanion _mapParticipantDomainToCompanion(SplitParticipant domain) {
    return SplitParticipantsCompanion(
      id: Value(domain.id),
      splitId: Value(domain.splitId),
      contactId: Value(domain.contactId),
      shareMinor: Value(domain.shareMinor),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
    );
  }

  @override
  Future<void> createSplit(
    Split split,
    List<SplitParticipant> participants, {
    String? accountId,
    String? categoryId,
    DateTime? occurredAt,
  }) async {
    await _db.transaction(() async {
      String? originId = split.originLedgerEntryId;

      if (accountId != null && occurredAt != null) {
        originId = _uuid.v4();
        // Create base transaction
        final entry = LedgerEntriesCompanion(
          id: Value(originId),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
          amountMinor: Value(split.totalMinor),
          direction: Value(MoneyDirection.outflow.index),
          origin: Value(LedgerOrigin.manual.index),
          occurredAt: Value(occurredAt.millisecondsSinceEpoch),
          note: Value(split.title),
          createdAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          syncStatus: Value(SyncStatus.localOnly.index),
        );
        await _db.into(_db.ledgerEntries).insert(entry);
      }

      final updatedSplit = split.copyWith(originLedgerEntryId: originId);
      await _db.into(_db.splits).insert(_mapSplitDomainToCompanion(updatedSplit));

      for (final part in participants) {
        final updatedPart = part.copyWith(splitId: updatedSplit.id);
        await _db.into(_db.splitParticipants).insert(_mapParticipantDomainToCompanion(updatedPart));
      }
    });
  }

  @override
  Future<void> deleteSplit(String splitId) async {
    await _db.transaction(() async {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.splits)..where((t) => t.id.equals(splitId))).write(
        SplitsCompanion(
          deletedAt: Value(nowMs),
          syncStatus: Value(SyncStatus.pendingUpload.index),
        ),
      );
    });
  }

  @override
  Future<void> recordRepayment(
    String splitId,
    String contactId,
    String accountId,
    int amountMinor,
    DateTime occurredAt,
    String? note,
  ) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final entryId = _uuid.v4();

      // Create inflow ledger entry for the repayment
      final entry = LedgerEntriesCompanion(
        id: Value(entryId),
        accountId: Value(accountId),
        splitId: Value(splitId),
        amountMinor: Value(amountMinor),
        direction: Value(MoneyDirection.inflow.index),
        origin: Value(LedgerOrigin.splitSettlement.index),
        occurredAt: Value(occurredAt.millisecondsSinceEpoch),
        note: Value(note ?? "Repayment"),
        metadataJson: Value(jsonEncode({'contact_id': contactId})),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.localOnly.index),
      );
      await _db.into(_db.ledgerEntries).insert(entry);

      // Check if this split is now fully settled
      final remaining = await getRemainingBalance(splitId);
      if (remaining <= 0) {
        await (_db.update(_db.splits)..where((t) => t.id.equals(splitId))).write(
          SplitsCompanion(
            status: Value(SplitStatus.settled.index),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    });
  }

  @override
  Future<Split?> getById(String id) async {
    final query = _db.select(_db.splits)..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapSplitRowToDomain(row) : null;
  }

  @override
  Future<List<Split>> getAll() async {
    final query = _db.select(_db.splits)..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapSplitRowToDomain).toList();
  }

  @override
  Stream<List<Split>> watchAllActive() {
    final query = _db.select(_db.splits)..where((t) => t.status.equals(SplitStatus.active.index) & t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapSplitRowToDomain).toList());
  }

  @override
  Stream<List<Split>> watchAllSettled() {
    final query = _db.select(_db.splits)..where((t) => t.status.equals(SplitStatus.settled.index) & t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapSplitRowToDomain).toList());
  }

  @override
  Stream<List<SplitParticipant>> watchParticipantsForSplit(String splitId) {
    final query = _db.select(_db.splitParticipants)..where((t) => t.splitId.equals(splitId));
    return query.watch().map((rows) => rows.map(_mapParticipantRowToDomain).toList());
  }

  @override
  Future<List<SplitParticipant>> getParticipantsForSplit(String splitId) async {
    final query = _db.select(_db.splitParticipants)..where((t) => t.splitId.equals(splitId));
    final rows = await query.get();
    return rows.map(_mapParticipantRowToDomain).toList();
  }

  @override
  Future<int> getRemainingBalance(String splitId) async {
    final splitQuery = _db.select(_db.splits)..where((t) => t.id.equals(splitId));
    final split = await splitQuery.getSingleOrNull();
    if (split == null) return 0;

    // Get all participants total expected shares
    final participantsQuery = _db.select(_db.splitParticipants)..where((t) => t.splitId.equals(splitId));
    final participants = await participantsQuery.get();
    final totalExpected = participants.fold<int>(0, (sum, p) => sum + p.shareMinor);

    // Get all received repayments
    final ledgerQuery = _db.select(_db.ledgerEntries)
      ..where((t) => t.splitId.equals(splitId) & t.direction.equals(MoneyDirection.inflow.index) & t.deletedAt.isNull());
    final repayments = await ledgerQuery.get();
    final totalPaid = repayments.fold<int>(0, (sum, r) => sum + r.amountMinor);

    return totalExpected - totalPaid;
  }
}
