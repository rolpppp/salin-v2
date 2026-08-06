import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/routing/app_router.dart';
import 'core/services/sync/sync_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: "assets/salin.env");
  } catch (e) {
    debugPrint('Could not load assets/salin.env file: $e');
  }
  
  final prefs = await SharedPreferences.getInstance();

  if (!SupabaseConfig.isPlaceholder) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SalinApp(),
    ),
  );
}

class SalinApp extends ConsumerWidget {
  const SalinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    final themeMode = settingsAsync.when(
      data: (settings) => settings.themeMode == 1 ? ThemeMode.dark : ThemeMode.light,
      loading: () => ThemeMode.light,
      error: (_, _) => ThemeMode.light,
    );

    return MaterialApp.router(
      title: 'Salin',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
