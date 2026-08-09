import 'package:flutter/material.dart';

/// Shared top chrome for every onboarding page: a back arrow (pages 2 and
/// 3 only) on the left, and a Skip/Not now button (every page) on the
/// right. Both are ≥48×48dp tap targets.
class OnboardingTopBar extends StatelessWidget {
  final int currentPage;
  final String skipLabel;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const OnboardingTopBar({
    super.key,
    required this.currentPage,
    required this.skipLabel,
    required this.onSkip,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: currentPage > 0
                ? IconButton(
                    onPressed: onBack,
                    tooltip: 'Back',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: Icon(Icons.arrow_back, color: onSurface.withOpacity(0.7)),
                  )
                : null,
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              skipLabel,
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 14,
                color: onSurface.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
