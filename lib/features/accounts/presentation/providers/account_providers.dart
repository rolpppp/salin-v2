import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepositoryImpl(db);
});

final accountsListProvider = StreamProvider<List<Account>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAll();
});

final accountBalanceProvider = StreamProvider.family<int, String>((ref, accountId) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchBalance(accountId);
});

final totalBalanceProvider = Provider<AsyncValue<int>>((ref) {
  final accountsAsync = ref.watch(accountsListProvider);
  final entriesAsync = ref.watch(ledgerEntriesListProvider);

  return accountsAsync.when(
    data: (accounts) {
      return entriesAsync.when(
        data: (entries) {
          int total = accounts.fold(0, (sum, acc) => sum + acc.openingBalanceMinor);
          for (final entry in entries) {
            final direction = entry.direction;
            if (direction == MoneyDirection.inflow) {
              total += entry.amountMinor;
            } else {
              total -= entry.amountMinor;
            }
          }
          return AsyncValue.data(total);
        },
        error: (err, stack) => AsyncValue.error(err, stack),
        loading: () => const AsyncValue.loading(),
      );
    },
    error: (err, stack) => AsyncValue.error(err, stack),
    loading: () => const AsyncValue.loading(),
  );
});

