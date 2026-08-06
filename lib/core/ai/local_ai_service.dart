import 'package:flutter/services.dart';

class LocalAIService {
  static const _channel = MethodChannel('app.salin/local_ai');

  /// Detects if the device has compatible native NPU & downloadable Gemini Nano / Apple Models.
  Future<bool> isHardwareSupported() async {
    try {
      final bool? supported = await _channel.invokeMethod<bool>('isHardwareSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sends strict system prompt instructions and user input to the native OS compiler.
  Future<String?> parseLocal(String systemPrompt, String userInput) async {
    try {
      final fullPrompt = "$systemPrompt\n\nUser Input: \"$userInput\"";
      final String? response = await _channel.invokeMethod('parseLocal', {
        'prompt': fullPrompt,
      });
      return response;
    } on PlatformException catch (_) {
      // Return null to trigger cloud fallback silently
      return null;
    }
  }
}
