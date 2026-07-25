import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/repositories/contact_repository_impl.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ContactRepositoryImpl(db);
});

final contactsListProvider = StreamProvider<List<Contact>>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return repo.watchAllActive();
});
