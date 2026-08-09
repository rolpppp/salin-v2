import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Onboarding screen 1 of 4 — "Welcome". States the app's core promise
/// inside a single card on an otherwise empty white page, then hands off
/// straight to the baseline question. No tutorial carousel, no reassurance
/// screens — one card, one button.
class OnboardingPageOne extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingPageOne({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Deliberately the app's plain white surface, not a tinted
            // "paper" card — the primary background must read as white.
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "What's left?",
                style: AppTheme.displayHero.copyWith(color: colorScheme.onSurface, fontSize: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'Salin helps you track what you can actually spend after the '
                'things that matter. No accounts, no login, just clarity.',
                style: AppTheme.bodyLg.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'START WITH A ROUGH ESTIMATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
