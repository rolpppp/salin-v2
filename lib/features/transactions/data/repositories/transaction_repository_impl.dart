import 'dart:async';
import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/tables/tables.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../../../core/ai/parsed_transaction.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;

  TransactionRepositoryImpl(this._db);

  // Mappers - LedgerEntry
  LedgerEntry _mapLedgerEntryRowToDomain(LedgerEntryRow row) {
    return LedgerEntry(
      id: row.id,
      accountId: row.accountId,
      categoryId: row.categoryId,
      recurringInstanceId: row.recurringInstanceId,
      debtId: row.debtId,
      splitId: row.splitId,
      transferId: row.transferId,
      amountMinor: row.amountMinor,
      direction: MoneyDirection.values[row.direction],
      origin: LedgerOrigin.values[row.origin],
      occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
      note: row.note,
      metadataJson: row.metadataJson,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true)
          : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  LedgerEntriesCompanion _mapLedgerEntryDomainToCompanion(LedgerEntry domain) {
    return LedgerEntriesCompanion(
      id: Value(domain.id),
      accountId: Value(domain.accountId),
      categoryId: Value(domain.categoryId),
      recurringInstanceId: Value(domain.recurringInstanceId),
      debtId: Value(domain.debtId),
      splitId: Value(domain.splitId),
      transferId: Value(domain.transferId),
      amountMinor: Value(domain.amountMinor),
      direction: Value(domain.direction.index),
      origin: Value(domain.origin.index),
      occurredAt: Value(domain.occurredAt.millisecondsSinceEpoch),
      note: Value(domain.note),
      metadataJson: Value(domain.metadataJson),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  // Mappers - Category
  Category _mapCategoryRowToDomain(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      categoryType: CategoryType.values[row.categoryType],
      isSystem: row.isSystem,
      displayOrder: row.displayOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true)
          : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  CategoriesCompanion _mapCategoryDomainToCompanion(Category domain) {
    return CategoriesCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      icon: Value(domain.icon),
      color: Value(domain.color),
      categoryType: Value(domain.categoryType.index),
      isSystem: Value(domain.isSystem),
      displayOrder: Value(domain.displayOrder),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  // Mappers - Transfer
  Transfer _mapTransferRowToDomain(TransferRow row) {
    return Transfer(
      id: row.id,
      fromAccountId: row.fromAccountId,
      toAccountId: row.toAccountId,
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true)
          : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  TransfersCompanion _mapTransferDomainToCompanion(Transfer domain) {
    return TransfersCompanion(
      id: Value(domain.id),
      fromAccountId: Value(domain.fromAccountId),
      toAccountId: Value(domain.toAccountId),
      note: Value(domain.note),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  // Implementation - Ledger Entries
  @override
  Future<void> createLedgerEntry(LedgerEntry entry) async {
    await _db.into(_db.ledgerEntries).insert(_mapLedgerEntryDomainToCompanion(entry));
  }

  @override
  Future<LedgerEntry> createFromParsed(
    ParsedTransaction parsed, {
    required String accountId,
    String? categoryId,
  }) async {
    final entry = LedgerEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      accountId: accountId,
      categoryId: categoryId ?? parsed.category,
      amountMinor: parsed.amountMinor ?? 0,
      direction: parsed.transactionType.toLowerCase() == 'income'
          ? MoneyDirection.inflow
          : MoneyDirection.outflow,
      origin: LedgerOrigin.quickAdd,
      occurredAt: parsed.transactionDate ?? DateTime.now(),
      note: parsed.description +
          (parsed.notes != null && parsed.notes!.isNotEmpty ? '\n${parsed.notes}' : ''),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      syncStatus: SyncStatus.localOnly,
    );
    await createLedgerEntry(entry);
    return entry;
  }

  @override
  Future<void> updateLedgerEntry(LedgerEntry entry) async {
    await (_db.update(_db.ledgerEntries)..where((t) => t.id.equals(entry.id)))
        .write(_mapLedgerEntryDomainToCompanion(entry));
  }

  @override
  Future<void> deleteLedgerEntry(String id) async {
    await (_db.update(_db.ledgerEntries)..where((t) => t.id.equals(id))).write(
      LedgerEntriesCompanion(
        deletedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.pendingUpload.index),
      ),
    );
  }

  @override
  Future<LedgerEntry?> getLedgerEntryById(String id) async {
    final query = _db.select(_db.ledgerEntries)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapLedgerEntryRowToDomain(row) : null;
  }

  @override
  Stream<List<LedgerEntry>> watchAllLedgerEntries() {
    final query = _db.select(_db.ledgerEntries)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapLedgerEntryRowToDomain).toList());
  }

  @override
  Stream<List<LedgerEntry>> watchLedgerEntriesByAccount(String accountId) {
    final query = _db.select(_db.ledgerEntries)
      ..where((t) => t.accountId.equals(accountId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapLedgerEntryRowToDomain).toList());
  }

  @override
  Future<List<LedgerEntry>> getLedgerEntriesByAccount(String accountId) async {
    final query = _db.select(_db.ledgerEntries)
      ..where((t) => t.accountId.equals(accountId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)]);
    final rows = await query.get();
    return rows.map(_mapLedgerEntryRowToDomain).toList();
  }

  @override
  Stream<List<LedgerEntry>> watchLedgerEntriesByCategory(String categoryId) {
    final query = _db.select(_db.ledgerEntries)
      ..where((t) => t.categoryId.equals(categoryId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapLedgerEntryRowToDomain).toList());
  }

  @override
  Future<List<LedgerEntry>> getAllLedgerEntries() async {
    final query = _db.select(_db.ledgerEntries)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)]);
    final rows = await query.get();
    return rows.map(_mapLedgerEntryRowToDomain).toList();
  }

  // Implementation - Categories
  @override
  Future<void> createCategory(Category category) async {
    await _db.into(_db.categories).insert(_mapCategoryDomainToCompanion(category));
  }

  @override
  Future<void> updateCategory(Category category) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(category.id)))
        .write(_mapCategoryDomainToCompanion(category));
  }

  @override
  Future<void> deleteCategory(String id) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.pendingUpload.index),
      ),
    );
  }

  @override
  Future<void> archiveCategory(String id, {required bool isArchived}) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(isArchived ? DateTime.now().toUtc().millisecondsSinceEpoch : null),
        syncStatus: Value(SyncStatus.pendingUpload.index),
      ),
    );
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final query = _db.select(_db.categories)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapCategoryRowToDomain(row) : null;
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    final query = _db.select(_db.categories)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.displayOrder)]);
    return query.watch().map((rows) => rows.map(_mapCategoryRowToDomain).toList());
  }

  @override
  Future<List<Category>> getAllCategories() async {
    final query = _db.select(_db.categories)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.displayOrder)]);
    final rows = await query.get();
    return rows.map(_mapCategoryRowToDomain).toList();
  }

  // Implementation - Transfers
  @override
  Future<void> createTransfer(Transfer transfer, {required int amountMinor, required DateTime occurredAt}) async {
    await _db.transaction(() async {
      await _db.into(_db.transfers).insert(_mapTransferDomainToCompanion(transfer));

      final outflowEntry = LedgerEntriesCompanion(
        id: Value('${transfer.id}_out'),
        accountId: Value(transfer.fromAccountId),
        transferId: Value(transfer.id),
        amountMinor: Value(amountMinor),
        direction: Value(MoneyDirection.outflow.index),
        origin: Value(LedgerOrigin.transfer.index),
        occurredAt: Value(occurredAt.millisecondsSinceEpoch),
        note: Value(transfer.note),
        createdAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.localOnly.index),
      );
      await _db.into(_db.ledgerEntries).insert(outflowEntry);

      final inflowEntry = LedgerEntriesCompanion(
        id: Value('${transfer.id}_in'),
        accountId: Value(transfer.toAccountId),
        transferId: Value(transfer.id),
        amountMinor: Value(amountMinor),
        direction: Value(MoneyDirection.inflow.index),
        origin: Value(LedgerOrigin.transfer.index),
        occurredAt: Value(occurredAt.millisecondsSinceEpoch),
        note: Value(transfer.note),
        createdAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.localOnly.index),
      );
      await _db.into(_db.ledgerEntries).insert(inflowEntry);
    });
  }

  @override
  Future<void> deleteTransfer(String id) async {
    await _db.transaction(() async {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.transfers)..where((t) => t.id.equals(id))).write(
        TransfersCompanion(
          deletedAt: Value(nowMs),
          syncStatus: Value(SyncStatus.pendingUpload.index),
        ),
      );

      await (_db.update(_db.ledgerEntries)..where((t) => t.transferId.equals(id))).write(
        LedgerEntriesCompanion(
          deletedAt: Value(nowMs),
          syncStatus: Value(SyncStatus.pendingUpload.index),
        ),
      );
    });
  }

  @override
  Future<Transfer?> getTransferById(String id) async {
    final query = _db.select(_db.transfers)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapTransferRowToDomain(row) : null;
  }
}
