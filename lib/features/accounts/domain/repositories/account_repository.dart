import '../entities/account.dart';

abstract class AccountRepository {
  Future<void> create(Account account);
  Future<void> update(Account account);
  Future<void> delete(String id);
  Future<void> archive(String id, {required bool isArchived});
  Future<Account?> getById(String id);
  Stream<List<Account>> watchAll();
  Future<List<Account>> getAll();
  Stream<int> watchBalance(String accountId);
}
