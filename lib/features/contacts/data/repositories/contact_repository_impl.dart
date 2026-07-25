import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/tables/tables.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final AppDatabase _db;

  ContactRepositoryImpl(this._db);

  Contact _mapRowToDomain(ContactRow row) {
    return Contact(
      id: row.id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      avatarPath: row.avatarPath,
      notes: row.notes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true) : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  ContactsCompanion _mapDomainToCompanion(Contact domain) {
    return ContactsCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      phone: Value(domain.phone),
      email: Value(domain.email),
      avatarPath: Value(domain.avatarPath),
      notes: Value(domain.notes),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  @override
  Future<void> create(Contact contact) async {
    await _db.into(_db.contacts).insert(_mapDomainToCompanion(contact));
  }

  @override
  Future<void> update(Contact contact) async {
    await (_db.update(_db.contacts)..where((t) => t.id.equals(contact.id)))
        .write(_mapDomainToCompanion(contact));
  }

  @override
  Future<void> delete(String id) async {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      ContactsCompanion(
        deletedAt: Value(nowMs),
        syncStatus: Value(SyncStatus.pendingUpload.index),
      ),
    );
  }

  @override
  Future<Contact?> getById(String id) async {
    final query = _db.select(_db.contacts)..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapRowToDomain(row) : null;
  }

  @override
  Future<List<Contact>> getAll() async {
    final query = _db.select(_db.contacts)..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRowToDomain).toList();
  }

  @override
  Stream<List<Contact>> watchAllActive() {
    final query = _db.select(_db.contacts)..where((t) => t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRowToDomain).toList());
  }
}
