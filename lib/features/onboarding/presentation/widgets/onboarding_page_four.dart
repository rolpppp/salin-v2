import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../accounts/presentation/providers/account_providers.dart';

/// Onboarding screen 4 of 4 — "Final Salin", the aha moment. Shows exactly
/// how the expense logged on screen 3 affected the baseline set on screen
/// 2. [baselineMinor] is the exact value screen 2 just wrote (passed down,
/// not re-derived from accountsListProvider) — that stream may not have
/// emitted its first value yet on this screen's first frame, which would
/// otherwise render a transient/wrong ₱0.00. The hero "remaining" figure
/// still reads the real totalBalanceProvider so it can never disagree with
/// what Home shows a moment later; baselineMinor is only its fallback while
/// that stream is still loading.
class OnboardingPageFour extends ConsumerWidget {
  final int baselineMinor;
  final int? loggedAmountMinor;
  final String? loggedDescription;
  final VoidCallback onFinish;

  const OnboardingPageFour({
    super.key,
    required this.baselineMinor,
    required this.loggedAmountMinor,
    required this.loggedDescription,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalAsync = ref.watch(totalBalanceProvider);
    final remainingMinor = totalAsync.maybeWhen(
      data: (value) => value,
      orElse: () => baselineMinor - (loggedAmountMinor ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Your Salin.',
          textAlign: TextAlign.center,
          style: AppTheme.headlineLg.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          'All set and ready to track.',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMd.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
              Text(
                'REMAINING BALANCE',
                style: AppTheme.labelCaps.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 8),
              MoneyText(
                amountMinor: remainingMinor,
                style: AppTheme.displayHero.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              Text(
                'This is what you have left to spend after your planned allocations.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySm.copyWith(color: colorScheme.onSurface.withOpacity(0.6), height: 1.4),
              ),
              const SizedBox(height: 20),
              Divider(color: colorScheme.onSurface.withOpacity(0.08), height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Baseline', style: AppTheme.bodyMd.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                  MoneyText(amountMinor: baselineMinor, style: AppTheme.dataMono.copyWith(color: colorScheme.onSurface)),
                ],
              ),
              if (loggedAmountMinor != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        loggedDescription ?? 'Allocated',
                        style: AppTheme.bodyMd.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    MoneyText(
                      amountMinor: loggedAmountMinor!,
                      isNegative: true,
                      style: AppTheme.dataMono.copyWith(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text(
              'Take me home',
              style: TextStyle(fontFamily: 'PublicSans', fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
