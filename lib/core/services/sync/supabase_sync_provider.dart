import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cloud_sync_provider.dart';

class SupabaseSyncProvider implements CloudSyncProvider {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<bool> register(String email, String password) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      return response.user != null;
    } catch (e) {
      debugPrint('SupabaseSyncProvider.register error: $e');
      return false;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      return response.user != null;
    } catch (e) {
      debugPrint('SupabaseSyncProvider.login error: $e');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('SupabaseSyncProvider.logout error: $e');
    }
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    try {
      return _client.auth.currentUser?.email;
    } catch (e) {
      debugPrint('SupabaseSyncProvider.getCurrentUserEmail error: $e');
      return null;
    }
  }

  @override
  Future<SyncPushResult> push({
    required Map<String, List<Map<String, dynamic>>> changes,
    Map<String, List<Map<String, dynamic>>>? relations,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return SyncPushResult(success: false, error: 'User is not authenticated');
      }

      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      // Helper to add metadata and scope to user
      List<Map<String, dynamic>> _prepareRecords(List<Map<String, dynamic>> records) {
        return records.map((r) => {
          ...r,
          'user_id': userId,
          'updatedAt': nowMs, // Server updatedAt
        }).toList();
      }

      // Upsert main changes
      for (final entry in changes.entries) {
        if (entry.value.isEmpty) continue;
        final prepared = _prepareRecords(entry.value);
        await _client.from(entry.key).upsert(prepared);
      }

      // Upsert relational records (e.g. mapping tables budget_categories, split_participants)
      if (relations != null) {
        for (final entry in relations.entries) {
          if (entry.value.isEmpty) continue;
          final prepared = _prepareRecords(entry.value);
          await _client.from(entry.key).upsert(prepared);
        }
      }

      return SyncPushResult(success: true);
    } catch (e) {
      debugPrint('SupabaseSyncProvider.push error: $e');
      return SyncPushResult(success: false, error: e.toString());
    }
  }

  @override
  Future<SyncPullResult> pull(int sinceTimestamp) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return SyncPullResult(
          success: false,
          serverTime: 0,
          changes: {},
          relations: {},
          error: 'User is not authenticated',
        );
      }

      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      final changes = <String, List<Map<String, dynamic>>>{};
      final relations = <String, List<Map<String, dynamic>>>{};

      final mainTables = [
        'accounts',
        'ledger_entries',
        'budgets',
        'categories',
        'contacts',
        'debts',
        'splits',
        'recurring_rules',
        'recurring_instances',
        'transfers'
      ];

      final relationTables = [
        'budget_categories',
        'split_participants'
      ];

      // Pull updates for main tables
      for (final table in mainTables) {
        final List<dynamic> response = await _client
            .from(table)
            .select()
            .eq('user_id', userId)
            .gt('updatedAt', sinceTimestamp);
        
        if (response.isNotEmpty) {
          changes[table] = response.cast<Map<String, dynamic>>();
        }
      }

      // Pull updates for relation mapping tables
      for (final table in relationTables) {
        final List<dynamic> response = await _client
            .from(table)
            .select()
            .eq('user_id', userId)
            .gt('updatedAt', sinceTimestamp);
        
        if (response.isNotEmpty) {
          relations[table] = response.cast<Map<String, dynamic>>();
        }
      }

      return SyncPullResult(
        success: true,
        serverTime: nowMs,
        changes: changes,
        relations: relations,
      );
    } catch (e) {
      debugPrint('SupabaseSyncProvider.pull error: $e');
      return SyncPullResult(
        success: false,
        serverTime: 0,
        changes: {},
        relations: {},
        error: e.toString(),
      );
    }
  }

  @override
  Future<bool> uploadBackup(String backupName, String encryptedData) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('SupabaseSyncProvider.uploadBackup error: User is not authenticated.');
        return false;
      }

      // Upsert a cloud backup record inside a 'backups' table
      await _client.from('backups').upsert({
        'name': backupName,
        'user_id': userId,
        'data': encryptedData,
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncProvider.uploadBackup error: $e');
      return false;
    }
  }

  @override
  Future<String?> downloadLatestBackup() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('SupabaseSyncProvider.downloadLatestBackup error: User is not authenticated.');
        return null;
      }

      final List<dynamic> response = await _client
          .from('backups')
          .select('data')
          .eq('user_id', userId)
          .order('updatedAt', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return response.first['data'] as String?;
    } catch (e) {
      debugPrint('SupabaseSyncProvider.downloadLatestBackup error: $e');
      return null;
    }
  }
}
