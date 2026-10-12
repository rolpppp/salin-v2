import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/balance_adjustment.dart';
import '../../domain/entities/account.dart';
import '../providers/account_providers.dart';

/// Opens the "Set real balances" form as a bottom sheet.
///
/// Pass [daysAway] for the welcome-back prompt ("Welcome back! It's been N
/// days."); leave it null for the manual entry point on the Accounts screen.
Future<void> showUpdateBalancesSheet(BuildContext context, {int? daysAway}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => UpdateBalancesSheet(daysAway: daysAway),
  );
}

/// The form: one "Real" field per active account, prefilled with what Salin
/// computes, a live per-account difference, and a summary before saving.
/// Business math lives in `balance_adjustment.dart` and the repository.
class UpdateBalancesSheet extends ConsumerStatefulWidget {
  final int? daysAway;

  const UpdateBalancesSheet({super.key, this.daysAway});

  @override
  ConsumerState<UpdateBalancesSheet> createState() => _UpdateBalancesSheetState();
}

class _UpdateBalancesSheetState extends ConsumerState<UpdateBalancesSheet> {
  final Map<String, TextEditingController> _controllers = {};

  /// What Salin computed when the form opened; the prefill and the base for
  /// the live differences.
  final Map<String, int> _computed = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureControllers(List<Account> accounts, Map<String, int> balances) {
    for (final a in accounts) {
      if (_controllers.containsKey(a.id)) continue;
      final computed = balances[a.id] ?? a.openingBalanceMinor;
      _computed[a.id] = computed;
      _controllers[a.id] = TextEditingController(text: minorToInputText(computed));
    }
  }

  /// accountId -> parsed real balance, or null when the field is unparsable.
  int? _realFor(Account a) => parseCentavos(_controllers[a.id]!.text);

  Future<void> _save(List<Account> accounts) async {
    final real = <String, int>{};
    for (final a in accounts) {
      final v = _realFor(a);
      if (v == null) return;
      real[a.id] = v;
    }
    setState(() => _saving = true);
    final written =
        await ref.read(transactionRepositoryProvider).applyBalanceAdjustments(real);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(
        written.length == 1
            ? 'Balance updated for 1 account.'
            : 'Balances updated for ${written.length} accounts.',
        style: const TextStyle(fontFamily: 'PublicSans'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final accounts = (accountsAsync.value ?? const <Account>[])
        .where((a) => !a.isArchived)
        .toList();
    final balances = balancesAsync.value;

    Widget body;
    if (balances == null) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (accounts.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No accounts to update yet.', style: TextStyle(fontFamily: 'PublicSans')),
      );
    } else {
      _ensureControllers(accounts, balances);
      var changed = 0;
      var allValid = true;
      for (final a in accounts) {
        final real = _realFor(a);
        if (real == null) {
          allValid = false;
        } else if (real != _computed[a.id]) {
          changed++;
        }
      }
      final canSave = allValid && changed > 0 && !_saving;

      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              children: [
                for (final a in accounts) _accountRow(context, a),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                !allValid
                    ? 'Enter each balance as an amount, like 1,250.50.'
                    : changed == 0
                        ? 'Nothing to correct yet. Change a balance to match what you really hold.'
                        : '$changed ${changed == 1 ? 'account' : 'accounts'} will be corrected; '
                            'recorded as Balance adjustment, history kept.',
                key: const Key('balances_summary'),
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 13,
                  color: allValid ? onSurface.withValues(alpha: 0.7) : AppTheme.inkRed,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(widget.daysAway != null ? 'Skip' : 'Cancel',
                          style: const TextStyle(fontFamily: 'PublicSans')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: canSave ? () => _save(accounts) : null,
                      child: const Text('Update balances',
                          style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final days = widget.daysAway;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (days != null) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      "Welcome back! It's been $days days.",
                      style: const TextStyle(fontFamily: 'PublicSans', fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 4),
                ] else
                  Semantics(
                    header: true,
                    child: const Text(
                      'Update balances',
                      style: TextStyle(fontFamily: 'PublicSans', fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                Text(
                  'Type what each account really holds now. Salin records the difference; nothing is deleted or edited.',
                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Flexible(child: body),
        ],
      ),
    );
  }

  Widget _accountRow(BuildContext context, Account a) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final computed = _computed[a.id]!;
    final real = _realFor(a);
    final invalid = real == null;
    final diff = invalid ? null : real - computed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.name,
              style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            'Salin says ${formatMinor(computed, currency: a.currency)}',
            style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          TextField(
            key: Key('real_${a.id}'),
            controller: _controllers[a.id],
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-−]'))],
            style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Real balance, ${a.name} (${a.currency})',
              hintText: '0.00',
              errorText: invalid ? 'Enter an amount like 1,250.50' : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (diff != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                diff == 0
                    ? 'No change'
                    : 'Difference ${formatMinor(diff, currency: a.currency, showSign: true)}',
                key: Key('diff_${a.id}'),
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: diff == 0
                      ? onSurface.withValues(alpha: 0.5)
                      : (diff < 0 ? AppTheme.inkRed : AppTheme.registerGreen),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
