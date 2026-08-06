import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url {
    try {
      return dotenv.env['SUPABASE_URL'] ?? 'https://placeholder-project.supabase.co';
    } catch (_) {
      return 'https://placeholder-project.supabase.co';
    }
  }

  static String get anonKey {
    try {
      return dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key-string-replace-me';
    } catch (_) {
      return 'placeholder-anon-key-string-replace-me';
    }
  }

  /// Checks if the config contains placeholder values.
  static bool get isPlaceholder =>
      url.contains('placeholder-project') || anonKey.contains('placeholder-anon-key');
}
