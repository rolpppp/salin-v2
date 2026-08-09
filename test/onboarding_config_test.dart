import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/config/onboarding_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingConfig.shouldShowOnboarding', () {
    test('fresh install (no keys at all) shows onboarding', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(OnboardingConfig.shouldShowOnboarding(prefs), isTrue);
    });

    test('already completed does not show onboarding again', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.completedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(OnboardingConfig.shouldShowOnboarding(prefs), isFalse);
    });

    test(
        'a pre-onboarding install that looks like an existing user (has '
        'toggled the Quick Add/Manual preference before) is retroactively '
        'marked complete instead of shown onboarding', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.existingUserHeuristicKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(OnboardingConfig.shouldShowOnboarding(prefs), isFalse);
      // The one-time correction must be persisted so future launches don't
      // need to re-evaluate the heuristic.
      expect(prefs.getBool(OnboardingConfig.completedKey), isTrue);
    });

    test('a brand-new user who has never touched entry mode still sees it',
        () async {
      // Simulates a fresh install with unrelated keys already present
      // (e.g. theme preference) but no capture-screen usage yet.
      SharedPreferences.setMockInitialValues({
        'some_unrelated_setting': 'value',
      });
      final prefs = await SharedPreferences.getInstance();

      expect(OnboardingConfig.shouldShowOnboarding(prefs), isTrue);
    });
  });
}
