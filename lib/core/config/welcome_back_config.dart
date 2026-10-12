import 'package:shared_preferences/shared_preferences.dart';

/// Days away after which the "Welcome back" balance prompt appears.
/// The single place this threshold lives.
const int kWelcomeBackThresholdDays = 14;

/// Device-local "when did the user last open Salin" state.
///
/// Lives in [SharedPreferences] (like onboarding state): it is presentation
/// state for this device, not financial data, and must not sync or travel
/// with a backup.
class WelcomeBackConfig {
  WelcomeBackConfig._();

  /// UTC epoch milliseconds of the last time the app came to the foreground.
  static const String lastOpenedKey = 'last_opened_at_ms';

  /// Pure check: whole days between [lastOpened] and [now] if that is at
  /// least [kWelcomeBackThresholdDays], else `null`. `null` [lastOpened]
  /// (fresh install) never triggers.
  static int? daysAwayIfDue(DateTime? lastOpened, DateTime now) {
    if (lastOpened == null) return null;
    final days = now.difference(lastOpened).inDays;
    return days >= kWelcomeBackThresholdDays ? days : null;
  }

  /// Reads the previous open time, stamps [now] as the new one, and returns
  /// the days away when the welcome-back prompt is due. Call on every
  /// foreground (cold start and resume).
  static Future<int?> recordOpen(SharedPreferences prefs, DateTime now) async {
    final lastMs = prefs.getInt(lastOpenedKey);
    final last = lastMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: true);
    final nowUtc = now.toUtc();
    await prefs.setInt(lastOpenedKey, nowUtc.millisecondsSinceEpoch);
    return daysAwayIfDue(last, nowUtc);
  }
}
