import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_provider.dart';

class MockSyncProvider implements CloudSyncProvider {
  static const String _mockDbKey = 'mock_cloud_db';
  static const String _mockBackupKey = 'mock_cloud_backup';
  static const String _mockUserKey = 'mock_cloud_user';

  final SharedPreferences _prefs;

  MockSyncProvider(this._prefs);

  String? _currentUserEmail;

  @override
  Future<bool> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network latency
    _currentUserEmail = email;
    await _prefs.setString(_mockUserKey, email);
    return true;
  }

  @override
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUserEmail = email;
    await _prefs.setString(_mockUserKey, email);
    return true;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserEmail = null;
    await _prefs.remove(_mockUserKey);
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    _currentUserEmail ??= _prefs.getString(_mockUserKey);
    return _currentUserEmail;
  }

  Map<String, dynamic> _getMockDb() {
    final raw = _prefs.getString(_mockDbKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMockDb(Map<String, dynamic> db) async {
    await _prefs.setString(_mockDbKey, jsonEncode(db));
  }

  @override
  Future<SyncPushResult> push({
    required Map<String, List<Map<String, dynamic>>> changes,
    Map<String, List<Map<String, dynamic>>>? relations,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final email = await getCurrentUserEmail();
    if (email == null) {
      return SyncPushResult(success: false, error: 'User is not authenticated');
    }

    final db = _getMockDb();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Process main changes
    changes.forEach((table, records) {
      final existingList = (db[table] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final updatedList = List<Map<String, dynamic>>.from(existingList);

      for (final record in records) {
        final id = record['id'];
        final index = updatedList.indexWhere((r) => r['id'] == id);

        final upsertRecord = {
          ...record,
          'user_id': email,
          'updated_at': nowMs, // Server updated_at timestamp
        };

        if (index >= 0) {
          updatedList[index] = upsertRecord;
        } else {
          updatedList.add(upsertRecord);
        }
      }
      db[table] = updatedList;
    });

    // Process relation changes (e.g. budget categories or split participants)
    if (relations != null) {
      relations.forEach((table, records) {
        final existingList = (db[table] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final updatedList = List<Map<String, dynamic>>.from(existingList);

        for (final record in records) {
          final id = record['id'];
          final index = updatedList.indexWhere((r) => r['id'] == id);

          final upsertRecord = {
            ...record,
            'user_id': email,
            'updated_at': nowMs,
          };

          if (index >= 0) {
            updatedList[index] = upsertRecord;
          } else {
            updatedList.add(upsertRecord);
          }
        }
        db[table] = updatedList;
      });
    }

    await _saveMockDb(db);
    return SyncPushResult(success: true);
  }

  @override
  Future<SyncPullResult> pull(int sinceTimestamp) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final email = await getCurrentUserEmail();
    if (email == null) {
      return SyncPullResult(
        success: false,
        serverTime: 0,
        changes: {},
        relations: {},
        error: 'User is not authenticated',
      );
    }

    final db = _getMockDb();
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
      'transfers',
      'media'
    ];

    db.forEach((table, recordsList) {
      final list = (recordsList as List<dynamic>).cast<Map<String, dynamic>>();
      final filtered = list.where((r) {
        final userId = r['user_id'];
        final updatedAt = r['updated_at'] as int;
        return userId == email && updatedAt > sinceTimestamp;
      }).toList();

      if (filtered.isNotEmpty) {
        if (mainTables.contains(table)) {
          changes[table] = filtered;
        } else {
          relations[table] = filtered;
        }
      }
    });

    return SyncPullResult(
      success: true,
      serverTime: nowMs,
      changes: changes,
      relations: relations,
    );
  }

  @override
  Future<bool> uploadBackup(String backupName, String encryptedData) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final email = await getCurrentUserEmail();
    if (email == null) return false;

    final backups = _prefs.getStringList(_mockBackupKey) ?? [];
    final backupMap = {
      'name': backupName,
      'user_id': email,
      'data': encryptedData,
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
    backups.add(jsonEncode(backupMap));
    await _prefs.setStringList(_mockBackupKey, backups);
    return true;
  }

  @override
  Future<String?> downloadLatestBackup() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final email = await getCurrentUserEmail();
    if (email == null) return null;

    final backups = _prefs.getStringList(_mockBackupKey) ?? [];
    if (backups.isEmpty) return null;

    final userBackups = backups.map((b) => jsonDecode(b) as Map<String, dynamic>).where((b) => b['user_id'] == email).toList();

    if (userBackups.isEmpty) return null;

    // Sort by timestamp descending
    userBackups.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return userBackups.first['data'] as String?;
  }
}
