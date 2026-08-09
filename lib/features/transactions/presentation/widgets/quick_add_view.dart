import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/review_item.dart';
import '../../../../core/ai/ai_validator.dart';
import '../../../../core/config/ai_config.dart';
import '../providers/transaction_providers.dart';
import '../providers/transaction_review_provider.dart';

/// The "Quick Add" tab of the New Entry sheet: a single free-text input that
/// gets parsed by the AI service, producing a queue of review cards the user
/// must confirm — individually or all at once — before anything saves.
class QuickAddView extends ConsumerStatefulWidget {
  const QuickAddView({super.key});

  @override
  ConsumerState<QuickAddView> createState() => _QuickAddViewState();
}

class _QuickAddViewState extends ConsumerState<QuickAddView> {
  final _inputController = TextEditingController();
  bool _isParsing = false;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(milliseconds: 600));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (mounted) {
        setState(() {
          _isOfflineMode = !online;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOfflineMode = true;
        });
      }
    }
  }

  Future<void> _handleParse() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isParsing = true);

    final aiService = ref.read(aiServiceProvider);
    final result = await aiService.parseTransaction(text);

    if (!mounted) return;
    setState(() => _isParsing = false);

    if (result.isSuccess) {
      final parsedData = result.parsedData!;
      final accounts = (ref.read(accountsListProvider).value ?? []).where((a) => !a.isArchived).toList();
      final defaultAccountId = accounts.isNotEmpty ? accounts.first.id : null;

      if (parsedData.length == 1 && defaultAccountId != null) {
        final parsed = parsedData.first;
        final warnings = AIValidator.validate(parsed);
        if (warnings.isEmpty) {
          final account = accounts.first;
          // Capture the repository instance itself (not a deferred `ref.read`)
          // so UNDO still works if the user navigates away and this widget
          // is disposed before the snackbar action is tapped — `ref` is tied
          // to this State's lifecycle, but the repository object is not.
          final repo = ref.read(transactionRepositoryProvider);
          final createdEntry = await repo.createFromParsed(parsed, accountId: defaultAccountId);
          _inputController.clear();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved ₱${(parsed.amountMinor! / 100).toStringAsFixed(2)} · ${parsed.description} → ${account.name}'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () async {
                  await repo.deleteLedgerEntry(createdEntry.id);
                },
              ),
            ),
          );
          // Re-check connectivity so the offline banner (if any) reflects
          // live state rather than only what was known at screen-open.
          _checkConnectivity();
          return;
        }
      }

      for (final parsed in parsedData) {
        ref.read(transactionReviewProvider.notifier).stageTransaction(text, parsed);
      }
      _inputController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Could not parse that — try rewording it.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewItems = ref.watch(transactionReviewProvider);
    final accountsAsync = ref.watch(accountsListProvider);
    final activeAccounts = (accountsAsync.value ?? []).where((a) => !a.isArchived).toList();
    // Free-form parsing (e.g. "Spent ₱150 on coffee at Ozone") only actually
    // works when Cloud AI is on and reachable; Cloud AI defaults to off, so
    // the input hint should show the structured format that always works
    // offline unless the user has actually opted into cloud fallback.
    final cloudAiEnabled = ref.watch(cloudAiEnabledProvider);
    final showStructuredHint = _isOfflineMode || !cloudAiEnabled;
    final defaultAccountId = activeAccounts.isNotEmpty ? activeAccounts.first.id : null;
    final defaultAccountName = activeAccounts.isNotEmpty ? activeAccounts.first.name : null;
    final hasBlockingItem = reviewItems.any((item) => item.warnings.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isOfflineMode) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.wifi_off_outlined, color: AppTheme.warningAmber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Offline Mode Active',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.warningAmber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format: One transaction per line.\n'
                          'Use "<amount> <description>" or "<description> <amount>".\n'
                          'Add optional category with #tag (e.g. 150 grab #transport).',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _inputController,
                    autofocus: true,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(fontFamily: 'PublicSans', fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      // The structured-format example intentionally matches
                      // onboarding page 3's taught example ("Lunch 180") —
                      // that screen is the first thing most users see before
                      // this field, so its lesson and this hint must agree.
                      hintText: showStructuredHint
                          ? "Enter transactions, one per line...\ne.g. 'Lunch 180'"
                          : "Paste a receipt, bank SMS, or describe your transaction...\ne.g., 'Spent ₱150 on coffee at Ozone yesterday'",
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06))),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _isParsing ? null : _handleParse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isParsing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Parse', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (reviewItems.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Parsed Transactions', style: TextStyle(fontFamily: 'PublicSans', fontSize: 15, fontWeight: FontWeight.w600)),
                Text('${reviewItems.length} ITEMS FOUND', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 12),
            ...reviewItems.map((item) => _ReviewCard(item: item, defaultAccountId: defaultAccountId, defaultAccountName: defaultAccountName)),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (defaultAccountId == null || hasBlockingItem)
                    ? null
                    : () => ref.read(transactionReviewProvider.notifier).confirmAll(accountId: defaultAccountId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasBlockingItem ? Theme.of(context).colorScheme.onSurface.withOpacity(0.08) : Theme.of(context).colorScheme.primary,
                  foregroundColor: hasBlockingItem ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Colors.white,
                  disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(hasBlockingItem ? Icons.lock_outline : Icons.check, size: 16),
                label: Text(
                  hasBlockingItem ? 'Confirm All (Review Needed)' : 'Confirm All',
                  style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final ReviewItem item;
  final String? defaultAccountId;
  final String? defaultAccountName;

  const _ReviewCard({required this.item, required this.defaultAccountId, this.defaultAccountName});

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.read(categoriesListProvider);
    final categories = categoriesAsync.value ?? [];

    final descController = TextEditingController(text: item.transaction.description);
    final amountController = TextEditingController(
      text: item.transaction.amountMinor != null ? (item.transaction.amountMinor! / 100).toStringAsFixed(2) : '',
    );
    String? selectedCategoryId = item.transaction.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Transaction Details',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    style: const TextStyle(fontFamily: 'PublicSans'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount (₱)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontFamily: 'IBMPlexMono'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categories.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : null,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Uncategorized', style: TextStyle(fontFamily: 'PublicSans')),
                      ),
                      ...categories.map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name, style: const TextStyle(fontFamily: 'PublicSans')),
                      )),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        selectedCategoryId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final desc = descController.text.trim();
                      final amtVal = double.tryParse(amountController.text.trim()) ?? 0.0;
                      final amtMinor = amtVal > 0 ? (amtVal * 100).round() : null;

                      final updatedTx = item.transaction.copyWith(
                        description: desc,
                        amountMinor: amtMinor,
                        category: selectedCategoryId,
                        notes: null, // User edited it, clear format warnings!
                      );

                      ref.read(transactionReviewProvider.notifier).updateItem(item.id, updatedTx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsReview = item.warnings.isNotEmpty;
    final borderColor = needsReview ? AppTheme.warningAmber : AppTheme.registerGreen;
    final txn = item.transaction;
    final isIncome = txn.transactionType.toLowerCase() == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(txn.merchant ?? txn.description, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Text(
                txn.amountMinor != null ? '₱${(txn.amountMinor! / 100).toStringAsFixed(2)}' : '—',
                style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.w600, color: isIncome ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Chip(label: (txn.category ?? 'Uncategorized').toUpperCase()),
              const SizedBox(width: 8),
              _Chip(
                label: needsReview ? 'NEEDS REVIEW' : 'CONFIDENT',
                color: borderColor,
                icon: needsReview ? Icons.help_outline : Icons.check_circle_outline,
              ),
              const Spacer(),
              Text(
                txn.transactionDate != null ? _relativeLabel(txn.transactionDate!) : '',
                style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
          if (defaultAccountName != null) ...[
            const SizedBox(height: 6),
            Text(
              '→ $defaultAccountName',
              style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showEditSheet(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningAmber,
                    side: BorderSide(color: AppTheme.warningAmber.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Edit Details', style: TextStyle(fontFamily: 'PublicSans', fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: defaultAccountId == null || needsReview
                      ? null
                      : () => ref.read(transactionReviewProvider.notifier).confirmItem(item.id, accountId: defaultAccountId!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))),
                  ),
                  child: const Text('Looks Good', style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeLabel(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (local.year == now.year && local.month == now.month && local.day == now.day) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) return 'Yesterday';
    return '${local.month}/${local.day}';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const _Chip({required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.onSurface).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: color != null ? Border.all(color: color!.withOpacity(0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontFamily: 'PublicSans', fontSize: 10, fontWeight: FontWeight.bold, color: tone, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}