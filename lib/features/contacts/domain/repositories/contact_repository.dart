import '../entities/contact.dart';

abstract class ContactRepository {
  Future<void> create(Contact contact);
  Future<void> update(Contact contact);
  Future<void> delete(String id);
  Future<Contact?> getById(String id);
  Future<List<Contact>> getAll();
  Stream<List<Contact>> watchAllActive();
}
