import '../../../shared/enums/financial_enums.dart';

abstract class CloudSyncProvider {
  /// Sign up a new user with email and password.
  Future<bool> register(String email, String password);

  /// Log in an existing user with email and password.
  Future<bool> login(String email, String password);

  /// Log out the currently authenticated user.
  Future<void> logout();

  /// Retrieve the current authenticated user's email/identifier.
  Future<String?> getCurrentUserEmail();

  /// Push local changes to the cloud.
  ///
  /// Takes a map where keys are table names (e.g. 'accounts', 'ledger_entries')
  /// and values are lists of map representations of changed rows.
  /// Also takes auxiliary mapping tables like 'budget_categories' and 'split_participants'.
  Future<SyncPushResult> push({
    required Map<String, List<Map<String, dynamic>>> changes,
    Map<String, List<Map<String, dynamic>>>? relations,
  });

  /// Pull remote changes from the cloud.
  ///
  /// Returns all records updated after [sinceTimestamp].
  Future<SyncPullResult> pull(int sinceTimestamp);

  /// Upload a full encrypted backup file string to the cloud.
  Future<bool> uploadBackup(String backupName, String encryptedData);

  /// Download the latest encrypted backup file string.
  Future<String?> downloadLatestBackup();
}

class SyncPushResult {
  final bool success;
  final String? error;

  SyncPushResult({required this.success, this.error});
}

class SyncPullResult {
  final bool success;
  final int serverTime;
  final Map<String, List<Map<String, dynamic>>> changes;
  final Map<String, List<Map<String, dynamic>>> relations;
  final String? error;

  SyncPullResult({
    required this.success,
    required this.serverTime,
    required this.changes,
    required this.relations,
    this.error,
  });
}
