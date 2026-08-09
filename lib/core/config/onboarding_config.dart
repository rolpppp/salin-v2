import 'package:shared_preferences/shared_preferences.dart';

/// Device-local UX state for the first-run onboarding flow.
///
/// This intentionally lives in [SharedPreferences], not the Drift `settings`
/// table: that table syncs via Supabase/LWW and is included in the SQLite
/// backup/restore path, while "has this device seen onboarding" is purely
/// local presentation state that must never travel with a backup or a
/// synced account.
class OnboardingConfig {
  OnboardingConfig._();

  /// Marks the onboarding flow as finished (via its final CTA) or dismissed
  /// (via Skip/Not now) — both are terminal and equivalent for this flag.
  ///
  /// Bumped from `_v1` to `_v2` when onboarding was redesigned into the
  /// 4-screen baseline/try-it/aha flow, so users who already dismissed the
  /// old 3-screen flow see the new one once instead of never seeing it.
  static const String completedKey = 'onboarding_completed_v2';

  /// Written by [AddTransactionPage]'s `_setEntryMode` whenever a user
  /// switches between Quick Add / Manual. Its mere presence means this
  /// device used the capture screen before onboarding existed, which we
  /// use as a signal for "this is an existing user with real history."
  static const String existingUserHeuristicKey = 'preferred_show_quick_add';

  /// Decides whether onboarding should be shown, and applies the one-time
  /// retroactive correction described below. Call once, synchronously, at
  /// router construction.
  ///
  /// Every pre-onboarding install has no [completedKey] at all — the
  /// feature didn't exist before now — which would otherwise make an
  /// existing user with real transaction history see this flow. To avoid
  /// that we treat the presence of [existingUserHeuristicKey] as a proxy
  /// for "this device has used the app's capture screen before," and if
  /// so, retroactively mark onboarding complete instead of showing it.
  ///
  /// This is an imperfect but pragmatic heuristic — a returning user who
  /// happens to have never toggled that specific setting will see
  /// onboarding once (a one-tap Skip away, not harmful). A fully accurate
  /// check would require an async database read (does the ledger have any
  /// entries?), which would break the synchronous `initialLocation`
  /// computation `GoRouter` relies on elsewhere in this app. That tradeoff
  /// is intentional, not an oversight.
  static bool shouldShowOnboarding(SharedPreferences prefs) {
    final alreadyCompleted = prefs.getBool(completedKey) ?? false;
    if (alreadyCompleted) return false;

    final looksLikeExistingUser = prefs.containsKey(existingUserHeuristicKey);
    if (looksLikeExistingUser) {
      // Fire-and-forget: persist the correction so this device never
      // re-evaluates the heuristic on a future launch either.
      prefs.setBool(completedKey, true);
      return false;
    }

    return true;
  }
}
