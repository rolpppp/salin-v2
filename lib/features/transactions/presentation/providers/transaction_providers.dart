import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(db);
});

final categoriesListProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchAllCategories();
});

final ledgerEntriesListProvider = StreamProvider<List<LedgerEntry>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchAllLedgerEntries();
});

final ledgerEntriesByAccountProvider = StreamProvider.family<List<LedgerEntry>, String>((ref, accountId) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchLedgerEntriesByAccount(accountId);
});

/// Backs the Quick Add flow. No concrete AIProvider/AIAdapter is wired here
/// yet — passing none makes AIService return its built-in "no active AI
/// providers" result rather than throwing, so the UI can render gracefully
/// until a real Gemini-backed AIProvider implementation is plugged in here.
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});