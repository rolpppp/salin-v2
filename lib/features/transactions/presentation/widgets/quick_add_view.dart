import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/review_item.dart';
import '../providers/transaction_providers.dart';
import '../providers/transaction_review_provider.dart';

/// The "Quick Add" tab of the New Entry sheet: a single free-text input that
/// gets parsed by the AI service, producing a queue of review cards the user
/// must confirm — individually or all at once — before anything saves.
///
/// Nothing here invents new data-layer behavior; it's a UI wrapper around
/// the existing [aiServiceProvider] and [transactionReviewProvider].
class QuickAddView extends ConsumerStatefulWidget {
  const QuickAddView({super.key});

  @override
  ConsumerState<QuickAddView> createState() => _QuickAddViewState();
}

class _QuickAddViewState extends ConsumerState<QuickAddView> {
  final _inputController = TextEditingController();
  bool _isParsing = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
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
      ref.read(transactionReviewProvider.notifier).stageTransaction(text, result.parsedData!);
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
    final defaultAccountId = accountsAsync.value?.isNotEmpty == true ? accountsAsync.value!.first.id : null;
    final hasBlockingItem = reviewItems.any((item) => item.warnings.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.carbonText.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _inputController,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(fontFamily: 'PublicSans', fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Paste a receipt, bank SMS, or describe your transaction... "
                          "e.g., 'Spent ₱150 on coffee at Ozone yesterday'",
                      hintStyle: TextStyle(color: AppTheme.carbonText.withOpacity(0.35)),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: AppTheme.carbonText.withOpacity(0.06))),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 20, color: AppTheme.carbonText.withOpacity(0.5)),
                      const SizedBox(width: 14),
                      Icon(Icons.mic_none_outlined, size: 20, color: AppTheme.carbonText.withOpacity(0.5)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _isParsing ? null : _handleParse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.oceanBlue,
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
                Text('${reviewItems.length} ITEMS FOUND', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: AppTheme.carbonText.withOpacity(0.5), letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 12),
            ...reviewItems.map((item) => _ReviewCard(item: item, defaultAccountId: defaultAccountId)),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (defaultAccountId == null || hasBlockingItem)
                    ? null
                    : () => ref.read(transactionReviewProvider.notifier).confirmAll(accountId: defaultAccountId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.carbonText.withOpacity(0.08),
                  foregroundColor: AppTheme.carbonText.withOpacity(0.5),
                  disabledBackgroundColor: AppTheme.carbonText.withOpacity(0.08),
                  disabledForegroundColor: AppTheme.carbonText.withOpacity(0.4),
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

  const _ReviewCard({required this.item, required this.defaultAccountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsReview = item.warnings.isNotEmpty;
    final borderColor = needsReview ? AppTheme.warningAmber : AppTheme.registerGreen;
    final txn = item.transaction;
    final isIncome = txn.transactionType.toLowerCase() == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
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
                style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.w600, color: isIncome ? AppTheme.oceanBlue : AppTheme.carbonText),
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
                style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: AppTheme.carbonText.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Wired to the same field the manual form uses — swap
                    // in a category picker sheet here when one exists.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open category picker (reuse the one from the manual form).')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningAmber,
                    side: BorderSide(color: AppTheme.warningAmber.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Edit Category', style: TextStyle(fontFamily: 'PublicSans', fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: defaultAccountId == null || needsReview
                      ? null
                      : () => ref.read(transactionReviewProvider.notifier).confirmItem(item.id, accountId: defaultAccountId!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardBg,
                    foregroundColor: AppTheme.oceanBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppTheme.oceanBlue.withOpacity(0.3))),
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
    final tone = color ?? AppTheme.carbonText.withOpacity(0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.carbonText).withOpacity(0.1),
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