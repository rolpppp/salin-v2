import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_provider.dart';
import 'mock_sync_provider.dart';
import 'supabase_sync_provider.dart';
import '../../config/supabase_config.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final cloudSyncProvider = Provider<CloudSyncProvider>((ref) {
  if (SupabaseConfig.isPlaceholder) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return MockSyncProvider(prefs);
  } else {
    return SupabaseSyncProvider();
  }
});
