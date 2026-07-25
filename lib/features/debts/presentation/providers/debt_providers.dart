import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DebtRepositoryImpl(db);
});

final activeDebtsListProvider = StreamProvider<List<Debt>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchAllActive();
});

final settledDebtsListProvider = StreamProvider<List<Debt>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchAllSettled();
});

final debtRemainingBalanceProvider = StreamProvider.family<int, String>((ref, debtId) {
  final repo = ref.watch(debtRepositoryProvider);
  // Trigger update when ledger entries change
  ref.watch(ledgerEntriesListProvider);
  return Stream.fromFuture(repo.getRemainingBalance(debtId));
});
