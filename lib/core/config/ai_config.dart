import 'package:flutter_dotenv/flutter_dotenv.dart';

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
}
