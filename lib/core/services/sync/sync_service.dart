import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../database/database.dart';
import '../../database/database_provider.dart';
import '../../../shared/enums/financial_enums.dart';
import 'cloud_sync_provider.dart';
import 'sync_providers.dart';

class SyncService {
  final AppDatabase _db;
  final CloudSyncProvider _cloudProvider;

  SyncService(this._db, this._cloudProvider);

  /// Run a full synchronization cycle: push local changes, then pull remote changes.
  Future<SyncResult> synchronize() async {
    final email = await _cloudProvider.getCurrentUserEmail();
    if (email == null) {
      return SyncResult(success: false, error: 'User not authenticated.');
    }

    try {
      // 1. Push local changes
      final pushRes = await _pushLocalChanges();
      if (!pushRes.success) {
        return SyncResult(success: false, error: 'Sync push failed: ${pushRes.error}');
      }

      // 2. Pull remote changes
      final pullRes = await _pullRemoteChanges();
      if (!pullRes.success) {
        return SyncResult(success: false, error: 'Sync pull failed: ${pullRes.error}');
      }

      return SyncResult(success: true, lastSyncAt: pullRes.serverTime);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<SyncPushResult> _pushLocalChanges() async {
    final changes = <String, List<Map<String, dynamic>>>{};
    final relations = <String, List<Map<String, dynamic>>>{};

    // Lists to keep track of successfully pushed IDs per table
    final pushedIds = <String, List<String>>{};

    // Helper to query and serialize modified rows
    Future<void> _collectChanges<T extends Table, D>(
      TableInfo<T, D> table,
      String tableName,
      Expression<int> syncStatusCol,
      D Function(Map<String, dynamic>) fromJson,
    ) async {
      final query = _db.select(table)
        ..where((tbl) => syncStatusCol.isNotValue(SyncStatus.synced.index));
      final rows = await query.get();
      if (rows.isNotEmpty) {
        changes[tableName] = rows.map((r) {
          return (r as dynamic).toJson() as Map<String, dynamic>;
        }).toList();

        pushedIds[tableName] = rows.map((r) => (r as dynamic).id as String).toList();
      }
    }

    // Collect main tables
    await _collectChanges(_db.accounts, 'accounts', _db.accounts.syncStatus, AccountRow.fromJson);
    await _collectChanges(_db.categories, 'categories', _db.categories.syncStatus, CategoryRow.fromJson);
    await _collectChanges(_db.budgets, 'budgets', _db.budgets.syncStatus, BudgetRow.fromJson);
    await _collectChanges(_db.recurringRules, 'recurring_rules', _db.recurringRules.syncStatus, RecurringRuleRow.fromJson);
    await _collectChanges(_db.recurringInstances, 'recurring_instances', _db.recurringInstances.syncStatus, RecurringInstanceRow.fromJson);
    await _collectChanges(_db.contacts, 'contacts', _db.contacts.syncStatus, ContactRow.fromJson);
    await _collectChanges(_db.debts, 'debts', _db.debts.syncStatus, DebtRow.fromJson);
    await _collectChanges(_db.splits, 'splits', _db.splits.syncStatus, SplitRow.fromJson);
    await _collectChanges(_db.transfers, 'transfers', _db.transfers.syncStatus, TransferRow.fromJson);
    await _collectChanges(_db.ledgerEntries, 'ledger_entries', _db.ledgerEntries.syncStatus, LedgerEntryRow.fromJson);

    // Collect relational mapping tables for modified parent items
    final budgetIds = pushedIds['budgets'];
    if (budgetIds != null && budgetIds.isNotEmpty) {
      final query = _db.select(_db.budgetCategories)..where((t) => t.budgetId.isIn(budgetIds));
      final rows = await query.get();
      if (rows.isNotEmpty) {
        relations['budget_categories'] = rows.map((r) => r.toJson()).toList();
      }
    }

    final splitIds = pushedIds['splits'];
    if (splitIds != null && splitIds.isNotEmpty) {
      final query = _db.select(_db.splitParticipants)..where((t) => t.splitId.isIn(splitIds));
      final rows = await query.get();
      if (rows.isNotEmpty) {
        relations['split_participants'] = rows.map((r) => r.toJson()).toList();
      }
    }

    if (changes.isEmpty && relations.isEmpty) {
      return SyncPushResult(success: true);
    }

    // Call provider to push changes
    final result = await _cloudProvider.push(changes: changes, relations: relations);
    if (!result.success) return result;

    // On success, update local syncStatus of all pushed records to Synced in a transaction
    await _db.transaction(() async {
      Future<void> _markSynced<T extends Table, D>(
        TableInfo<T, D> table,
        List<String>? ids,
        dynamic companionCreator(int status),
      ) async {
        if (ids == null || ids.isEmpty) return;
        // Cast to dynamic to access id col
        await (_db.update(table)..where((tbl) => (tbl as dynamic).id.isIn(ids)))
            .write(companionCreator(SyncStatus.synced.index));
      }

      await _markSynced(_db.accounts, pushedIds['accounts'], (status) => AccountsCompanion(syncStatus: Value(status)));
      await _markSynced(_db.categories, pushedIds['categories'], (status) => CategoriesCompanion(syncStatus: Value(status)));
      await _markSynced(_db.budgets, pushedIds['budgets'], (status) => BudgetsCompanion(syncStatus: Value(status)));
      await _markSynced(_db.recurringRules, pushedIds['recurring_rules'], (status) => RecurringRulesCompanion(syncStatus: Value(status)));
      await _markSynced(_db.recurringInstances, pushedIds['recurring_instances'], (status) => RecurringInstancesCompanion(syncStatus: Value(status)));
      await _markSynced(_db.contacts, pushedIds['contacts'], (status) => ContactsCompanion(syncStatus: Value(status)));
      await _markSynced(_db.debts, pushedIds['debts'], (status) => DebtsCompanion(syncStatus: Value(status)));
      await _markSynced(_db.splits, pushedIds['splits'], (status) => SplitsCompanion(syncStatus: Value(status)));
      await _markSynced(_db.transfers, pushedIds['transfers'], (status) => TransfersCompanion(syncStatus: Value(status)));
      await _markSynced(_db.ledgerEntries, pushedIds['ledger_entries'], (status) => LedgerEntriesCompanion(syncStatus: Value(status)));
    });

    return SyncPushResult(success: true);
  }

  Future<SyncPullResult> _pullRemoteChanges() async {
    // Retrieve lastSyncAt from setting
    final settingsRow = await (_db.select(_db.settings)..limit(1)).getSingleOrNull();
    final lastSyncAt = settingsRow?.lastSyncAt ?? 0;

    final result = await _cloudProvider.pull(lastSyncAt);
    if (!result.success) return result;

    await _db.transaction(() async {
      // 1. Process main changes applying Last Write Wins
      Future<void> _processTableChanges<T extends Table, D>(
        TableInfo<T, D> table,
        List<Map<String, dynamic>>? remoteRecords,
        D Function(Map<String, dynamic>) fromJson,
        int Function(D) getUpdatedAt,
        String Function(D) getId,
      ) async {
        if (remoteRecords == null || remoteRecords.isEmpty) return;

        for (final record in remoteRecords) {
          final remoteDomain = fromJson(record);
          final id = getId(remoteDomain);

          // Query local record by ID (even if soft-deleted)
          final localQuery = _db.select(table)..where((tbl) => (tbl as dynamic).id.equals(id));
          final localRow = await localQuery.getSingleOrNull();

          if (localRow == null) {
            // Insert new record as Synced
            final map = {...record, 'syncStatus': SyncStatus.synced.index};
            final deserializedRow = fromJson(map);
            final companion = (deserializedRow as dynamic).toCompanion(true);
            await _db.into(table).insert(companion);
          } else {
            // Apply Last Write Wins
            final localUpdatedAt = (localRow as dynamic).updatedAt as int;
            final remoteUpdatedAt = getUpdatedAt(remoteDomain);

            if (remoteUpdatedAt > localUpdatedAt) {
              // Remote is newer, overwrite local as Synced
              final map = {...record, 'syncStatus': SyncStatus.synced.index};
              final deserializedRow = fromJson(map);
              final companion = (deserializedRow as dynamic).toCompanion(true);
              await (_db.update(table)..where((tbl) => (tbl as dynamic).id.equals(id))).write(companion);
            }
            // If local is newer or equal, we keep local record.
            // Its syncStatus remains unsynced (localOnly/pendingUpload) so it will be pushed next cycle.
          }
        }
      }

      await _processTableChanges(_db.accounts, result.changes['accounts'], AccountRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.categories, result.changes['categories'], CategoryRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.budgets, result.changes['budgets'], BudgetRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.recurringRules, result.changes['recurring_rules'], RecurringRuleRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.recurringInstances, result.changes['recurring_instances'], RecurringInstanceRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.contacts, result.changes['contacts'], ContactRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.debts, result.changes['debts'], DebtRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.splits, result.changes['splits'], SplitRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.transfers, result.changes['transfers'], TransferRow.fromJson, (r) => r.updatedAt, (r) => r.id);
      await _processTableChanges(_db.ledgerEntries, result.changes['ledger_entries'], LedgerEntryRow.fromJson, (r) => r.updatedAt, (r) => r.id);

      // 2. Process relation mapping tables (budget_categories and split_participants)
      Future<void> _processRelationChanges<T extends Table, D>(
        TableInfo<T, D> table,
        List<Map<String, dynamic>>? remoteRecords,
        D Function(Map<String, dynamic>) fromJson,
        String Function(D) getId,
      ) async {
        if (remoteRecords == null || remoteRecords.isEmpty) return;

        for (final record in remoteRecords) {
          final remoteDomain = fromJson(record);
          final id = getId(remoteDomain);

          final companion = (remoteDomain as dynamic).toCompanion(true);
          await _db.into(table).insertOnConflictUpdate(companion);
        }
      }

      await _processRelationChanges(_db.budgetCategories, result.relations['budget_categories'], BudgetCategoryRow.fromJson, (r) => r.id);
      await _processRelationChanges(_db.splitParticipants, result.relations['split_participants'], SplitParticipantRow.fromJson, (r) => r.id);

      // 3. Update lastSyncAt in local settings
      if (settingsRow != null) {
        await (_db.update(_db.settings)..where((t) => t.id.equals(settingsRow.id))).write(
          SettingsCompanion(
            lastSyncAt: Value(result.serverTime),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
      }
    });

    return result;
  }

  /// Exports the local database file as base64 string and uploads it as a cloud backup.
  Future<bool> cloudBackup() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'salin.db'));
      if (!await dbFile.exists()) {
        debugPrint('SyncService.cloudBackup error: Local database file does not exist.');
        return false;
      }

      final bytes = await dbFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupName = 'salin_cloud_backup_$timestamp.db';

      return await _cloudProvider.uploadBackup(backupName, base64String);
    } catch (e) {
      debugPrint('SyncService.cloudBackup error: $e');
      return false;
    }
  }

  /// Downloads the latest cloud backup and overwrites the local database.
  Future<bool> cloudRestore() async {
    try {
      final base64String = await _cloudProvider.downloadLatestBackup();
      if (base64String == null) {
        debugPrint('SyncService.cloudRestore error: Downloaded backup is null.');
        return false;
      }

      final bytes = base64Decode(base64String.trim());
      
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'salin.db'));

      // Close database connection
      await _db.close();

      // Keep a backup of current database
      final backupOfCurrent = File('${dbFile.path}.old');
      if (await dbFile.exists()) {
        await dbFile.copy(backupOfCurrent.path);
      }

      try {
        await dbFile.writeAsBytes(bytes);
        if (await backupOfCurrent.exists()) {
          await backupOfCurrent.delete();
        }
        return true;
      } catch (copyError) {
        debugPrint('SyncService.cloudRestore file copy error: $copyError');
        // Rollback on fail
        if (await backupOfCurrent.exists()) {
          await backupOfCurrent.copy(dbFile.path);
          await backupOfCurrent.delete();
        }
        return false;
      }
    } catch (e) {
      debugPrint('SyncService.cloudRestore error: $e');
      return false;
    }
  }
}

class SyncResult {
  final bool success;
  final int? lastSyncAt;
  final String? error;

  SyncResult({required this.success, this.lastSyncAt, this.error});
}

// Sync notifier managing the synchronization state (last sync time, active syncing status, error states)
class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? error;

  SyncState({
    required this.isSyncing,
    this.lastSyncTime,
    this.error,
  });

  factory SyncState.idle({DateTime? lastSyncTime}) => SyncState(isSyncing: false, lastSyncTime: lastSyncTime);
  factory SyncState.syncing({DateTime? lastSyncTime}) => SyncState(isSyncing: true, lastSyncTime: lastSyncTime);
  factory SyncState.error(String message, {DateTime? lastSyncTime}) => SyncState(isSyncing: false, error: message, lastSyncTime: lastSyncTime);
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  final SyncService _syncService;

  SyncNotifier(this._ref, this._syncService) : super(SyncState.idle()) {
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final db = _ref.read(databaseProvider);
    final settingsRow = await (db.select(db.settings)..limit(1)).getSingleOrNull();
    if (settingsRow != null && settingsRow.lastSyncAt != null) {
      state = SyncState.idle(lastSyncTime: DateTime.fromMillisecondsSinceEpoch(settingsRow.lastSyncAt!, isUtc: true));
    }
  }

  Future<bool> runSync() async {
    state = SyncState.syncing(lastSyncTime: state.lastSyncTime);
    final result = await _syncService.synchronize();
    if (result.success && result.lastSyncAt != null) {
      final syncTime = DateTime.fromMillisecondsSinceEpoch(result.lastSyncAt!, isUtc: true);
      state = SyncState.idle(lastSyncTime: syncTime);
      return true;
    } else {
      state = SyncState.error(result.error ?? 'Sync failed', lastSyncTime: state.lastSyncTime);
      return false;
    }
  }

  Future<bool> runCloudBackup() async {
    state = SyncState.syncing(lastSyncTime: state.lastSyncTime);
    final success = await _syncService.cloudBackup();
    state = SyncState.idle(lastSyncTime: state.lastSyncTime);
    return success;
  }

  Future<bool> runCloudRestore() async {
    state = SyncState.syncing(lastSyncTime: state.lastSyncTime);
    final success = await _syncService.cloudRestore();
    if (success) {
      // Reload sync details
      await _loadLastSyncTime();
      return true;
    } else {
      state = SyncState.idle(lastSyncTime: state.lastSyncTime);
      return false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final provider = ref.watch(cloudSyncProvider);
  return SyncService(db, provider);
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final service = ref.watch(syncServiceProvider);
  return SyncNotifier(ref, service);
});
