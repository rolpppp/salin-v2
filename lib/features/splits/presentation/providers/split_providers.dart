import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/repositories/split_repository_impl.dart';
import '../../domain/entities/split.dart';
import '../../domain/entities/split_participant.dart';
import '../../domain/repositories/split_repository.dart';

final splitRepositoryProvider = Provider<SplitRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SplitRepositoryImpl(db);
});

final activeSplitsListProvider = StreamProvider<List<Split>>((ref) {
  final repo = ref.watch(splitRepositoryProvider);
  return repo.watchAllActive();
});

final settledSplitsListProvider = StreamProvider<List<Split>>((ref) {
  final repo = ref.watch(splitRepositoryProvider);
  return repo.watchAllSettled();
});

final splitParticipantsListProvider = StreamProvider.family<List<SplitParticipant>, String>((ref, splitId) {
  final repo = ref.watch(splitRepositoryProvider);
  return repo.watchParticipantsForSplit(splitId);
});

final splitRemainingBalanceProvider = StreamProvider.family<int, String>((ref, splitId) {
  final repo = ref.watch(splitRepositoryProvider);
  // Trigger update when ledger entries change
  ref.watch(ledgerEntriesListProvider);
  return Stream.fromFuture(repo.getRemainingBalance(splitId));
});
