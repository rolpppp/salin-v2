import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/parsed_transaction.dart';
import '../../../../core/ai/rule_parser.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../../shared/widgets/money_text.dart';

/// Onboarding screen 3 of 4 — "Try it out". This IS the tutorial: no mock,
/// no rehearsal, no coach mark. The text field is the real offline rule
/// parser and "Log this expense" writes a real [LedgerEntry] through the
/// real repository — the same one `/add` uses.
class OnboardingPageThree extends ConsumerStatefulWidget {
  final void Function(int amountMinor, String description) onLogged;

  const OnboardingPageThree({super.key, required this.onLogged});

  @override
  ConsumerState<OnboardingPageThree> createState() => _OnboardingPageThreeState();
}

class _OnboardingPageThreeState extends ConsumerState<OnboardingPageThree> {
  final _controller = TextEditingController();
  final _parser = RuleParser();
  ParsedTransaction? _parsed;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTextChanged() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (_parsed != null) setState(() => _parsed = null);
      return;
    }
    try {
      final result = await _parser.parseTransaction(text);
      final list = result.parsedPayload;
      if (!mounted) return;
      setState(() => _parsed = list.isNotEmpty ? list.first : null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _parsed = null);
    }
  }

  String? _categoryLabel(String? categoryId) {
    if (categoryId == null) return null;
    final categories = ref.read(categoriesListProvider).value ?? [];
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return null;
  }

  Future<void> _logExpense() async {
    final parsed = _parsed;
    if (parsed == null || parsed.amountMinor == null || _isSaving) return;

    // Direct one-shot fetch, not accountsListProvider's cached stream value
    // — see onboarding_page_two.dart's identical fix for why.
    final accounts = await ref.read(accountRepositoryProvider).getAll();
    if (accounts.isEmpty) return;

    setState(() => _isSaving = true);
    final repo = ref.read(transactionRepositoryProvider);
    await repo.createFromParsed(parsed, accountId: accounts.first.id);
    if (!mounted) return;
    widget.onLogged(parsed.amountMinor!, parsed.description);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final parsed = _parsed;
    final hasValidAmount = parsed?.amountMinor != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Try it out.',
          textAlign: TextAlign.center,
          style: AppTheme.headlineLg.copyWith(color: colorScheme.primary, fontSize: 28),
        ),
        const SizedBox(height: 10),
        Text(
          "Just type what you spent, like you're writing a note.",
          textAlign: TextAlign.center,
          style: AppTheme.bodyMd.copyWith(color: colorScheme.onSurface.withOpacity(0.65), height: 1.4),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            style: AppTheme.dataMono.copyWith(color: colorScheme.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '150 jeepney fare...',
              hintStyle: AppTheme.dataMono.copyWith(color: colorScheme.onSurface.withOpacity(0.35)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: colorScheme.onSurface.withOpacity(0.45)),
            const SizedBox(width: 6),
            Text(
              'NATURAL LANGUAGE PARSE',
              style: AppTheme.labelCaps.copyWith(color: colorScheme.onSurface.withOpacity(0.45)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          child: hasValidAmount
              ? _InterpretationCard(
                  key: const ValueKey('parsed'),
                  parsed: parsed!,
                  categoryLabel: _categoryLabel(parsed.category),
                )
              : const _WaitingCard(key: ValueKey('waiting')),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasValidAmount && !_isSaving ? _logExpense : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              disabledBackgroundColor: colorScheme.primary.withOpacity(0.35),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_forward, size: 18),
            label: const Text(
              'Log this expense',
              style: TextStyle(fontFamily: 'PublicSans', fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// Idle state of the interpretation area, before the parser has anything to
/// show — mirrors the field it sits under rather than introducing a new
/// off-brand tint.
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            '• • •',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 18, letterSpacing: 4),
          ),
          const SizedBox(height: 8),
          Text(
            'WAITING FOR INPUT',
            style: AppTheme.labelCaps.copyWith(color: colorScheme.onSurface.withOpacity(0.35)),
          ),
        ],
      ),
    );
  }
}

/// What the real rule parser understood, shown before the user commits —
/// the review the AI pipeline requires, satisfied as an ambient preview
/// rather than a separate confirmation screen.
class _InterpretationCard extends StatelessWidget {
  final ParsedTransaction parsed;
  final String? categoryLabel;

  const _InterpretationCard({super.key, required this.parsed, this.categoryLabel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip(
            context,
            child: MoneyText(amountMinor: parsed.amountMinor!, style: AppTheme.dataMonoSm),
          ),
          _chip(context, child: Text(parsed.description, style: AppTheme.dataMonoSm.copyWith(color: colorScheme.onSurface))),
          if (categoryLabel != null)
            _chip(context, child: Text(categoryLabel!, style: AppTheme.dataMonoSm.copyWith(color: colorScheme.onSurface))),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
