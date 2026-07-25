import 'dart:async';
import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/tables/tables.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase _db;

  AccountRepositoryImpl(this._db);

  Account _mapRowToDomain(AccountRow row) {
    return Account(
      id: row.id,
      name: row.name,
      accountType: AccountType.values[row.accountType],
      openingBalanceMinor: row.openingBalanceMinor,
      currency: row.currency,
      icon: row.icon,
      color: row.color,
      displayOrder: row.displayOrder,
      isArchived: row.isArchived,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true)
          : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  AccountsCompanion _mapDomainToCompanion(Account domain) {
    return AccountsCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      accountType: Value(domain.accountType.index),
      openingBalanceMinor: Value(domain.openingBalanceMinor),
      currency: Value(domain.currency),
      icon: Value(domain.icon),
      color: Value(domain.color),
      displayOrder: Value(domain.displayOrder),
      isArchived: Value(domain.isArchived),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  @override
  Future<void> create(Account account) async {
    await _db.into(_db.accounts).insert(_mapDomainToCompanion(account));
  }

  @override
  Future<void> update(Account account) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(account.id)))
        .write(_mapDomainToCompanion(account));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        deletedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.pendingUpload.index),
      ),
    );
  }

  @override
  Future<void> archive(String id, {required bool isArchived}) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.pendingUpload.index),
      ),
    );
  }

  @override
  Future<Account?> getById(String id) async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapRowToDomain(row) : null;
  }

  @override
  Stream<List<Account>> watchAll() {
    final query = _db.select(_db.accounts)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.displayOrder)]);
    return query.watch().map((rows) => rows.map(_mapRowToDomain).toList());
  }

  @override
  Future<List<Account>> getAll() async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.displayOrder)]);
    final rows = await query.get();
    return rows.map(_mapRowToDomain).toList();
  }

  @override
  Stream<int> watchBalance(String accountId) {
    final query = _db.select(_db.accounts).join([
      leftOuterJoin(
        _db.ledgerEntries,
        _db.ledgerEntries.accountId.equalsExp(_db.accounts.id) &
            _db.ledgerEntries.deletedAt.isNull(),
      ),
    ])..where(_db.accounts.id.equals(accountId));

    return query.watch().map((rows) {
      if (rows.isEmpty) return 0;
      final account = rows.first.readTable(_db.accounts);
      int balance = account.openingBalanceMinor;
      
      for (final row in rows) {
        final entry = row.readTableOrNull(_db.ledgerEntries);
        if (entry != null) {
          final direction = MoneyDirection.values[entry.direction];
          if (direction == MoneyDirection.inflow) {
            balance += entry.amountMinor;
          } else {
            balance -= entry.amountMinor;
          }
        }
      }
      return balance;
    });
  }
}
