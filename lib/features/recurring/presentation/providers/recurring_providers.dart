import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/repositories/recurring_repository_impl.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/entities/recurring_instance.dart';
import '../../domain/repositories/recurring_repository.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RecurringRepositoryImpl(db);
});

final recurringRulesListProvider = StreamProvider<List<RecurringRule>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watchAllRules();
});

final upcomingInstancesListProvider = StreamProvider<List<RecurringInstance>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watchUpcomingInstances();
});
