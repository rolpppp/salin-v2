import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/database/database_provider.dart';
import 'package:salin/core/services/sync/mock_sync_provider.dart';
import 'package:salin/core/services/sync/sync_providers.dart';
import 'package:salin/core/services/sync/sync_service.dart';
import 'package:salin/features/auth/presentation/providers/auth_providers.dart';
import 'package:salin/shared/enums/financial_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late SharedPreferences prefs;
  late MockSyncProvider mockSyncProvider;
  late SyncService syncService;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    
    dotenv.testLoad(fileInput: 'SUPABASE_URL=https://placeholder-project.supabase.co\nSUPABASE_ANON_KEY=placeholder-anon-key-string-replace-me');
    database = AppDatabase(NativeDatabase.memory());
    mockSyncProvider = MockSyncProvider(prefs);
    syncService = SyncService(database, mockSyncProvider);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(prefs),
        cloudSyncProvider.overrideWithValue(mockSyncProvider),
        syncServiceProvider.overrideWithValue(syncService),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  group('Sprint 6 Sync Subsystem Tests', () {
    test('Authentication Registration & Login', () async {
      final authNotifier = container.read(authProvider.notifier);
      
      // Register
      final regSuccess = await authNotifier.register('test@salin.app', 'password123');
      expect(regSuccess, true);
      expect(container.read(authProvider).status, AuthStatus.authenticated);
      expect(container.read(authProvider).email, 'test@salin.app');

      // Logout
      await authNotifier.logout();
      expect(container.read(authProvider).status, AuthStatus.unauthenticated);

      // Login
      final loginSuccess = await authNotifier.login('test@salin.app', 'password123');
      expect(loginSuccess, true);
      expect(container.read(authProvider).status, AuthStatus.authenticated);
    });

    test('Incremental Push updates local syncStatus to synced', () async {
      // 1. Authenticate user
      await mockSyncProvider.login('test@salin.app', 'password123');

      // 2. Create account locally (Drift insert)
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await database.into(database.accounts).insert(
        AccountsCompanion.insert(
          id: 'acc_pocket',
          name: 'Pocket Cash',
          accountType: AccountType.cash.index,
          openingBalanceMinor: 50000,
          currency: 'PHP',
          icon: 'pocket',
          displayOrder: 1,
          isArchived: false,
          createdAt: nowMs,
          updatedAt: nowMs,
          syncStatus: SyncStatus.localOnly.index,
        ),
      );

      // Verify it is localOnly initially
      final localBefore = await (database.select(database.accounts)..where((t) => t.id.equals('acc_pocket'))).getSingle();
      expect(localBefore.syncStatus, SyncStatus.localOnly.index);

      // 3. Trigger sync push
      final result = await syncService.synchronize();
      expect(result.success, true);

      // 4. Verify local syncStatus updated to synced
      final localAfter = await (database.select(database.accounts)..where((t) => t.id.equals('acc_pocket'))).getSingle();
      expect(localAfter.syncStatus, SyncStatus.synced.index);
    });

    test('LWW Conflict Resolution - Remote newer overwrites local', () async {
      final email = 'test@salin.app';
      await mockSyncProvider.login(email, 'password123');

      // 1. Setup existing record locally with updatedAt = 1000
      await database.into(database.accounts).insert(
        AccountsCompanion.insert(
          id: 'acc_wallet',
          name: 'Local Wallet Name',
          accountType: AccountType.cash.index,
          openingBalanceMinor: 20000,
          currency: 'PHP',
          icon: 'wallet',
          displayOrder: 1,
          isArchived: false,
          createdAt: 1000,
          updatedAt: 1000,
          syncStatus: SyncStatus.synced.index,
        ),
      );

      // 2. Setup newer record on mock server (Supabase simulation) with updatedAt = 2000
      final changes = {
        'accounts': [
          {
            'id': 'acc_wallet',
            'name': 'Cloud Wallet Name',
            'accountType': AccountType.cash.index,
            'openingBalanceMinor': 20000,
            'currency': 'PHP',
            'icon': 'wallet',
            'displayOrder': 1,
            'isArchived': false,
            'createdAt': 1000,
            'updatedAt': 2000,
            'deletedAt': null,
            'syncStatus': SyncStatus.synced.index,
          }
        ]
      };
      await mockSyncProvider.push(changes: changes);

      // 3. Trigger sync pull
      final result = await syncService.synchronize();
      expect(result.success, true);

      // 4. Verify local database overwritten by remote newer record
      final localRecord = await (database.select(database.accounts)..where((t) => t.id.equals('acc_wallet'))).getSingle();
      expect(localRecord.name, 'Cloud Wallet Name');
      expect(localRecord.updatedAt, 2000);
      expect(localRecord.syncStatus, SyncStatus.synced.index);
    });

    test('LWW Conflict Resolution - Local newer is preserved and marked for push', () async {
      final email = 'test@salin.app';
      await mockSyncProvider.login(email, 'password123');

      // 1. Setup newer record locally with updatedAt = 2000 (modified locally)
      await database.into(database.accounts).insert(
        AccountsCompanion.insert(
          id: 'acc_wallet',
          name: 'Local Newer Name',
          accountType: AccountType.cash.index,
          openingBalanceMinor: 20000,
          currency: 'PHP',
          icon: 'wallet',
          displayOrder: 1,
          isArchived: false,
          createdAt: 1000,
          updatedAt: 2000,
          syncStatus: SyncStatus.pendingUpload.index,
        ),
      );

      // 2. Setup older record on mock server with updatedAt = 1500
      final changes = {
        'accounts': [
          {
            'id': 'acc_wallet',
            'name': 'Cloud Older Name',
            'accountType': AccountType.cash.index,
            'openingBalanceMinor': 20000,
            'currency': 'PHP',
            'icon': 'wallet',
            'displayOrder': 1,
            'isArchived': false,
            'createdAt': 1000,
            'updatedAt': 1500,
            'deletedAt': null,
            'syncStatus': SyncStatus.synced.index,
          }
        ]
      };
      // Simulating a state where the cloud has an older version
      await mockSyncProvider.push(changes: changes);

      // 3. Trigger sync (this will push local newer to server, then pull)
      final result = await syncService.synchronize();
      expect(result.success, true);

      // 4. Verify local record is preserved (newer local name wins)
      final localRecord = await (database.select(database.accounts)..where((t) => t.id.equals('acc_wallet'))).getSingle();
      expect(localRecord.name, 'Local Newer Name');
      expect(localRecord.syncStatus, SyncStatus.synced.index); // Pusher marked it synced after upload
    });

    test('Soft Delete Sync Cycle', () async {
      final email = 'test@salin.app';
      await mockSyncProvider.login(email, 'password123');

      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      // 1. Create a record locally
      await database.into(database.accounts).insert(
        AccountsCompanion.insert(
          id: 'acc_to_delete',
          name: 'Temporary Account',
          accountType: AccountType.cash.index,
          openingBalanceMinor: 10000,
          currency: 'PHP',
          icon: 'trash',
          displayOrder: 2,
          isArchived: false,
          createdAt: nowMs,
          updatedAt: nowMs,
          syncStatus: SyncStatus.localOnly.index,
        ),
      );

      // Sync once to establish the record on the mock server
      await syncService.synchronize();

      // 2. Perform soft delete locally (updatedAt = nowMs + 1000)
      await (database.update(database.accounts)..where((t) => t.id.equals('acc_to_delete'))).write(
        AccountsCompanion(
          deletedAt: Value(nowMs + 1000),
          updatedAt: Value(nowMs + 1000),
          syncStatus: Value(SyncStatus.pendingUpload.index),
        ),
      );

      // 3. Trigger sync push
      final result = await syncService.synchronize();
      expect(result.success, true);

      // 4. Verify mock server received the soft delete
      final pullResult = await mockSyncProvider.pull(0);
      final remoteAccount = pullResult.changes['accounts']!.firstWhere((a) => a['id'] == 'acc_to_delete');
      expect(remoteAccount['deletedAt'], nowMs + 1000);
      expect(remoteAccount['name'], 'Temporary Account');
    });
  });
}
