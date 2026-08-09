import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../accounts/presentation/providers/account_providers.dart';

/// Onboarding screen 2 of 4 — "Baseline Setup". Captures a single rough
/// peso amount and writes it directly as the seeded default account's
/// opening balance — the Single Number Baseline constraint: no account
/// picker, no multiple accounts, just one number that makes the rest of
/// the flow's arithmetic real instead of hypothetical.
class OnboardingPageTwo extends ConsumerStatefulWidget {
  final void Function(int baselineMinor) onContinue;

  const OnboardingPageTwo({super.key, required this.onContinue});

  @override
  ConsumerState<OnboardingPageTwo> createState() => _OnboardingPageTwoState();
}

class _OnboardingPageTwoState extends ConsumerState<OnboardingPageTwo> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;
    final value = double.tryParse(_controller.text.trim()) ?? 0.0;
    final minor = (value * 100).round();

    if (minor > 0) {
      setState(() => _isSaving = true);
      // A direct one-shot fetch, not accountsListProvider's cached stream
      // value — the stream may not have emitted yet this early in a fresh
      // session, which would silently no-op this write.
      final accounts = await ref.read(accountRepositoryProvider).getAll();
      if (accounts.isNotEmpty) {
        final account = accounts.first;
        final updated = account.copyWith(
          openingBalanceMinor: minor,
          updatedAt: DateTime.now().toUtc(),
          syncStatus: SyncStatus.localOnly,
        );
        await ref.read(accountRepositoryProvider).update(updated);
      }
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
    // Report the exact value just written (or 0, if it was skipped/blank)
    // rather than leaving screen 4 to re-derive it from accountsListProvider
    // — that stream may not have emitted its first value yet by the time
    // screen 4 renders, which would show a transient/wrong ₱0.00.
    widget.onContinue(minor > 0 ? minor : 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text(
          'How much is in your pocket right now?',
          textAlign: TextAlign.center,
          style: AppTheme.headlineLg.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        Text(
          "A rough estimate is fine. We'll handle the math later.",
          textAlign: TextAlign.center,
          style: AppTheme.bodyMd.copyWith(color: colorScheme.onSurface.withOpacity(0.65), height: 1.4),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.18)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(
                '₱',
                style: AppTheme.displayHero.copyWith(fontSize: 26, color: colorScheme.onSurface.withOpacity(0.45)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTheme.displayHero.copyWith(fontSize: 26, color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: AppTheme.displayHero.copyWith(fontSize: 26, color: colorScheme.onSurface.withOpacity(0.28)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAndContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'THAT LOOKS RIGHT',
                    style: TextStyle(fontFamily: 'PublicSans', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => widget.onContinue(0),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.onSurface.withOpacity(0.15)),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              "I'LL DO THIS LATER",
              style: TextStyle(fontFamily: 'PublicSans', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
