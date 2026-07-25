import '../entities/ledger_entry.dart';
import '../entities/category.dart';
import '../entities/transfer.dart';
import '../../../../core/ai/parsed_transaction.dart';

abstract class TransactionRepository {
  // Ledger Entries
  Future<void> createLedgerEntry(LedgerEntry entry);
  Future<void> updateLedgerEntry(LedgerEntry entry);
  Future<void> deleteLedgerEntry(String id);
  Future<LedgerEntry?> getLedgerEntryById(String id);
  Stream<List<LedgerEntry>> watchAllLedgerEntries();
  Stream<List<LedgerEntry>> watchLedgerEntriesByAccount(String accountId);
  Future<List<LedgerEntry>> getLedgerEntriesByAccount(String accountId);
  Stream<List<LedgerEntry>> watchLedgerEntriesByCategory(String categoryId);
  Future<List<LedgerEntry>> getAllLedgerEntries();
  
  // AI Conversion
  Future<LedgerEntry> createFromParsed(
    ParsedTransaction parsed, {
    required String accountId,
    String? categoryId,
  });

  // Categories
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<void> archiveCategory(String id, {required bool isArchived});
  Future<Category?> getCategoryById(String id);
  Stream<List<Category>> watchAllCategories();
  Future<List<Category>> getAllCategories();

  // Transfers
  Future<void> createTransfer(Transfer transfer, {required int amountMinor, required DateTime occurredAt});
  Future<void> deleteTransfer(String id);
  Future<Transfer?> getTransferById(String id);
}
