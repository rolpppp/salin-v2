import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIConfig {
  /// Retrieves the Gemini API Key from environment configuration.
  static String get geminiApiKey {
    try {
      return (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  /// Checks if the Gemini API Key is configured.
  static bool get hasApiKey => geminiApiKey.isNotEmpty;

  static const _cloudAiEnabledKey = 'cloud_ai_enabled';

  /// Whether the user has explicitly opted in to sending Quick Add text to
  /// the cloud (Gemini) provider. Defaults to false — cloud AI must be an
  /// explicit opt-in, never a silent default, per docs/AI_SPEC.md.
  static Future<bool> isCloudAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cloudAiEnabledKey) ?? false;
  }

  static Future<void> setCloudAiEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudAiEnabledKey, value);
  }
}

/// Reactive wrapper around [AIConfig]'s cloud AI consent flag so the
/// Settings UI can watch/toggle it without touching SharedPreferences
/// directly.
class CloudAiSettingNotifier extends StateNotifier<bool> {
  CloudAiSettingNotifier() : super(false) {
    AIConfig.isCloudAiEnabled().then((value) => state = value);
  }

  Future<void> setEnabled(bool value) async {
    await AIConfig.setCloudAiEnabled(value);
    state = value;
  }
}

final cloudAiEnabledProvider = StateNotifierProvider<CloudAiSettingNotifier, bool>(
  (ref) => CloudAiSettingNotifier(),
);
