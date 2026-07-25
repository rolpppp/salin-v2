import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/utils/category_icon_mapper.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../transactions/domain/entities/category.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/budget_providers.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsListProvider);
    final activeBudgetAsync = ref.watch(activeBudgetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyState(
              message: 'No active budgets created yet.',
              actionLabel: 'Set Up Budget',
              onAction: () => _showCreateBudgetDialog(context, ref),
            );
          }

          final activeBudget = activeBudgetAsync.value;

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              if (activeBudget != null) _ActiveBudgetCard(budgetId: activeBudget.id),

              const SizedBox(height: 20),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _showCreateBudgetDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.carbonText,
                    side: BorderSide(color: AppTheme.carbonText.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('NEW BUDGET', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),

              if (budgets.length > 1) ...[
                const SizedBox(height: 28),
                const Text(
                  'ALL BUDGETS',
                  style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: budgets.map((b) {
                      final isCurrent = activeBudget?.id == b.id;
                      return Column(
                        children: [
                          ListTile(
                            title: Text(b.name, style: TextStyle(fontFamily: 'PublicSans', fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                            subtitle: Text(
                              "${b.startDate.toLocal().toString().substring(0, 10)} to ${b.endDate.toLocal().toString().substring(0, 10)}",
                              style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(color: AppTheme.registerGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Active', style: TextStyle(color: AppTheme.registerGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.inkRed, size: 20),
                                  onPressed: () => _confirmDelete(context, ref, b),
                                ),
                              ],
                            ),
                          ),
                          if (b.id != budgets.last.id) const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${budget.name}"? Historical transactions remain unaffected.', style: const TextStyle(fontFamily: 'PublicSans')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans'))),
          ElevatedButton(
            onPressed: () async {
              await ref.read(budgetRepositoryProvider).delete(budget.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inkRed),
            child: const Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateBudgetDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => const _CreateBudgetFormSheet(),
    );
  }
}

class _ActiveBudgetCard extends ConsumerWidget {
  final String budgetId;

  const _ActiveBudgetCard({required this.budgetId});

  /// Same three-tier semantic scale used everywhere else in the app:
  /// green under 80%, amber 80–99%, red at/over 100%.
  Color _progressColor(double progress, bool isOverspent) {
    if (isOverspent) return AppTheme.inkRed;
    if (progress > 0.8) return AppTheme.warningAmber;
    return AppTheme.registerGreen;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(budgetSummaryProvider(budgetId));
    final categoriesAsync = ref.watch(categoriesListProvider);
    final categories = categoriesAsync.value ?? const <Category>[];

    return summaryAsync.when(
      data: (summary) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: TOTAL BUDGET label + month, hero figure, spent/remaining line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL BUDGET', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                Text(DateFormat('MMMM').format(summary.budget.startDate), style: const TextStyle(fontFamily: 'PublicSans', color: AppTheme.carbonText, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            MoneyText(
              amountMinor: summary.totalLimitMinor,
              muteDecimals: true,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AppTheme.carbonText),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Spent: ', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.carbonText.withOpacity(0.6))),
                MoneyText(amountMinor: summary.totalSpentMinor, style: const TextStyle(fontFamily: 'IBMPlexMono', color: AppTheme.carbonText)),
                const SizedBox(width: 16),
                Text('Remaining: ', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.carbonText.withOpacity(0.6))),
                MoneyText(amountMinor: summary.remainingMinor.abs(), style: const TextStyle(fontFamily: 'IBMPlexMono', color: AppTheme.oceanBlue, fontWeight: FontWeight.w600)),
              ],
            ),

            const SizedBox(height: 20),

            // Category rows
            ...summary.categorySummaries.map((cat) {
              final catProgress = cat.progress;
              final catOverspent = cat.isOverspent;
              final isPaidFixed = cat.limitMinor > 0 && cat.spentMinor == cat.limitMinor;
              final color = _progressColor(catProgress, catOverspent);
              final matched = categories.where((c) => c.id == cat.categoryId).toList();
              final iconKey = matched.isNotEmpty ? matched.first.icon : cat.categoryIcon;

              return Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.carbonText.withOpacity(0.06),
                      child: Icon(mapCategoryIcon(iconKey), size: 20, color: AppTheme.carbonText.withOpacity(0.7)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat.categoryName, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                              MoneyText(amountMinor: cat.spentMinor, style: const TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPaidFixed ? 'FIXED' : '${(catProgress * 100).clamp(0, 999).toStringAsFixed(0)}% SPENT',
                                style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: AppTheme.carbonText.withOpacity(0.5), letterSpacing: 0.5),
                              ),
                              Row(
                                children: [
                                  const Text('/ ', style: TextStyle(color: Colors.grey)),
                                  MoneyText(amountMinor: cat.limitMinor, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppTheme.carbonText.withOpacity(0.5))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isPaidFixed)
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: 1.0,
                                      minHeight: 6,
                                      backgroundColor: AppTheme.carbonText.withOpacity(0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.carbonText.withOpacity(0.15)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.registerGreen.withOpacity(0.5))),
                                  child: const Icon(Icons.check, size: 14, color: AppTheme.registerGreen),
                                ),
                              ],
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: catProgress > 1.0 ? 1.0 : catProgress,
                                minHeight: 6,
                                backgroundColor: AppTheme.carbonText.withOpacity(0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          if (!isPaidFixed) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('₱0', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppTheme.carbonText.withOpacity(0.4))),
                                Text(
                                  catOverspent ? 'Over budget' : '${NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(cat.remainingMinor / 100)} left',
                                  style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: catOverspent ? AppTheme.inkRed : AppTheme.carbonText.withOpacity(0.4)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const LoadingState(),
      error: (err, stack) => Center(child: Text("Error summary: $err")),
    );
  }
}

class _CreateBudgetFormSheet extends ConsumerStatefulWidget {
  const _CreateBudgetFormSheet();

  @override
  ConsumerState<_CreateBudgetFormSheet> createState() => _CreateBudgetFormSheetState();
}

class _CreateBudgetFormSheetState extends ConsumerState<_CreateBudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Map<String, TextEditingController> _limitControllers = {};

  BudgetPeriod _period = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _rollover = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final ctrl in _limitControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_period == BudgetPeriod.monthly) _endDate = DateTime(picked.year, picked.month + 1, picked.day);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2100));
    if (picked != null) setState(() => _endDate = picked);
  }

  void _saveBudget(List<Category> expenseCategories) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final budgetId = DateTime.now().millisecondsSinceEpoch.toString();

    final budget = Budget(
      id: budgetId,
      name: name,
      period: _period,
      startDate: _startDate.toUtc(),
      endDate: _endDate.toUtc(),
      rolloverEnabled: _rollover,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      syncStatus: SyncStatus.localOnly,
    );

    final budgetCategories = <BudgetCategory>[];
    for (final cat in expenseCategories) {
      final ctrl = _limitControllers[cat.id];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        final doubleLimit = double.tryParse(ctrl.text) ?? 0.0;
        if (doubleLimit > 0) {
          budgetCategories.add(BudgetCategory(
            id: "${budgetId}_${cat.id}",
            budgetId: budgetId,
            categoryId: cat.id,
            limitMinor: (doubleLimit * 100).round(),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ));
        }
      }
    }

    if (budgetCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please assign a limit to at least one category.')));
      return;
    }

    await ref.read(budgetRepositoryProvider).create(budget, budgetCategories);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final allCategories = categoriesAsync.value ?? [];
    final expenseCategories = allCategories.where((c) => c.categoryType == CategoryType.expense).toList();

    for (final cat in expenseCategories) {
      _limitControllers.putIfAbsent(cat.id, () => TextEditingController());
    }

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create New Budget', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Budget Name', hintText: 'e.g. July 2026'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetPeriod>(
                initialValue: _period,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(value: BudgetPeriod.monthly, child: Text('Monthly', style: TextStyle(fontFamily: 'PublicSans'))),
                  DropdownMenuItem(value: BudgetPeriod.custom, child: Text('Custom Range', style: TextStyle(fontFamily: 'PublicSans'))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _period = val;
                      if (val == BudgetPeriod.monthly) _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Colors.grey)),
                      subtitle: Text(_startDate.toString().substring(0, 10), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14)),
                      trailing: const Icon(Icons.calendar_today, size: 16),
                      onTap: () => _selectStartDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Colors.grey)),
                      subtitle: Text(_endDate.toString().substring(0, 10), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14)),
                      trailing: _period == BudgetPeriod.custom ? const Icon(Icons.calendar_today, size: 16) : null,
                      onTap: _period == BudgetPeriod.custom ? () => _selectEndDate(context) : null,
                    ),
                  ),
                ],
              ),
              const Divider(),
              SwitchListTile(
                value: _rollover,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.oceanBlue,
                title: const Text('Enable Rollover', style: TextStyle(fontFamily: 'PublicSans')),
                subtitle: const Text('Remaining amounts rollover to next period.', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11)),
                onChanged: (val) => setState(() => _rollover = val),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('CATEGORY LIMITS', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
              ),
              ...expenseCategories.map((cat) {
                final ctrl = _limitControllers[cat.id]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(cat.name, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600))),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: ctrl,
                          decoration: const InputDecoration(hintText: '0.00', prefixText: '₱ '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontFamily: 'IBMPlexMono'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _saveBudget(expenseCategories),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.oceanBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Budget', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}