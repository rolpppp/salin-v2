import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/database/database.dart';
import 'package:salin/core/theme/app_theme.dart';
import 'package:salin/features/settings/data/repositories/settings_repository_impl.dart';

void main() {
  group('AppTheme accent + brightness resolution', () {
    test('lightTheme() and darkTheme() have opposite brightness', () {
      expect(AppTheme.lightTheme().brightness, Brightness.light);
      expect(AppTheme.darkTheme().brightness, Brightness.dark);
    });

    test('lightTheme() and darkTheme() use distinct background/surface colors', () {
      final light = AppTheme.lightTheme();
      final dark = AppTheme.darkTheme();
      expect(light.scaffoldBackgroundColor, AppTheme.paperBg);
      expect(dark.scaffoldBackgroundColor, AppTheme.midnightBg);
      expect(light.scaffoldBackgroundColor, isNot(dark.scaffoldBackgroundColor));
      expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
      expect(light.colorScheme.onSurface, isNot(dark.colorScheme.onSurface));
    });

    test('different accent keys resolve to different, correct primary colors', () {
      for (final entry in AppTheme.accentPalette.entries) {
        final accent = AppTheme.resolveAccent(entry.key);
        expect(accent, entry.value);
        expect(AppTheme.lightTheme(accent).colorScheme.primary, entry.value);
        expect(AppTheme.darkTheme(accent).colorScheme.primary, entry.value);
      }

      // Two distinct accents must actually produce distinct primaries —
      // this is the exact thing that was broken (accent selection had no
      // effect anywhere, so every theme's primary was always oceanBlue).
      final ocean = AppTheme.lightTheme(AppTheme.resolveAccent('ocean')).colorScheme.primary;
      final forest = AppTheme.lightTheme(AppTheme.resolveAccent('forest')).colorScheme.primary;
      expect(ocean, isNot(forest));
    });

    test('unrecognized or null accent key falls back to oceanBlue', () {
      expect(AppTheme.resolveAccent('not-a-real-key'), AppTheme.oceanBlue);
      expect(AppTheme.resolveAccent(null), AppTheme.oceanBlue);
    });

    test('inverseSurface/onInverseSurface stay high-contrast in both themes', () {
      final light = AppTheme.lightTheme().colorScheme;
      final dark = AppTheme.darkTheme().colorScheme;
      // Light theme: dark fill, light foreground (a near-black button with
      // white-ish text, matching the original "stamped ledger" button look).
      expect(light.inverseSurface, AppTheme.carbonText);
      expect(light.onInverseSurface, AppTheme.paperBg);
      // Dark theme: inverted — light fill, dark foreground — so the same
      // button stays readable instead of white text disappearing onto a
      // light cream background (the regression the P0 fix here prevents).
      expect(dark.inverseSurface, AppTheme.carbonTextDark);
      expect(dark.onInverseSurface, AppTheme.midnightBg);
      expect(light.inverseSurface, isNot(dark.inverseSurface));
    });
  });

  group('Settings persistence for theme choices', () {
    late AppDatabase database;
    late SettingsRepositoryImpl repo;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repo = SettingsRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('themeMode and accentTheme round-trip through the repository', () async {
      final defaults = await repo.getSettings();
      expect(defaults.themeMode, 0); // light by default
      expect(defaults.accentTheme, 'ocean'); // default accent

      await repo.updateSettings(defaults.copyWith(themeMode: 1, accentTheme: 'forest'));
      final updated = await repo.getSettings();

      expect(updated.themeMode, 1);
      expect(updated.accentTheme, 'forest');

      // Replicates exactly what SalinApp.build() does with these fields.
      final resolvedMode = updated.themeMode == 1 ? ThemeMode.dark : ThemeMode.light;
      final resolvedAccent = AppTheme.resolveAccent(updated.accentTheme);
      expect(resolvedMode, ThemeMode.dark);
      expect(resolvedAccent, AppTheme.accentPalette['forest']);
    });
  });
}
