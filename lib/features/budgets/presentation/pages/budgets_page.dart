import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/utils/category_icon_mapper.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/error_state.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBudgetDialog(context, ref),
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
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
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('NEW BUDGET', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),

              if (budgets.length > 1) ...[
                const SizedBox(height: 28),
                Text(
                  'ALL BUDGETS',
                  style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: budgets.map((b) {
                      final isCurrent = activeBudget?.id == b.id;
                      return Column(
                        children: [
                          Dismissible(
                            key: Key(b.id),
                            dismissThresholds: const {
                              DismissDirection.startToEnd: 0.65,
                              DismissDirection.endToStart: 0.65,
                            },
                            background: Container(
                              color: AppTheme.warningAmber.withOpacity(0.15),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_outlined, color: AppTheme.warningAmber),
                                  SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.warningAmber, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            secondaryBackground: Container(
                              color: AppTheme.inkRed.withOpacity(0.15),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.inkRed, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete_outline, color: AppTheme.inkRed),
                                ],
                              ),
                            ),
                             confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                _showEditBudgetDialog(context, b);
                                return false;
                              } else {
                                bool deleteConfirmed = false;
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Budget', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
                                    content: const Text('Are you sure you want to delete this budget and all its category links? Historical transaction logs remain untouched.', style: TextStyle(fontFamily: 'PublicSans')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inkRed),
                                        onPressed: () {
                                          deleteConfirmed = true;
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (deleteConfirmed) {
                                  final budgetToUndo = b;
                                  final repo = ref.read(budgetRepositoryProvider);
                                  final categoriesToUndo = await repo.getCategoriesForBudget(b.id);
                                  await repo.delete(b.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Budget "${budgetToUndo.name}" deleted.', style: const TextStyle(fontFamily: 'PublicSans')),
                                        action: SnackBarAction(
                                          label: 'UNDO',
                                          onPressed: () async {
                                            await repo.create(budgetToUndo, categoriesToUndo);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  return true;
                                }
                                return false;
                              }
                            },
                            child: ListTile(
                              title: Text(b.name, style: TextStyle(fontFamily: 'PublicSans', fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                              subtitle: Text(
                                "${b.startDate.toLocal().toString().substring(0, 10)} to ${b.endDate.toLocal().toString().substring(0, 10)}",
                                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12),
                              ),
                              trailing: isCurrent
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppTheme.registerGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Active', style: TextStyle(color: AppTheme.registerGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  : null,
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
        error: (err, stack) => ErrorState(errorMessage: err.toString()),
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
              final categoriesToUndo = await ref.read(budgetRepositoryProvider).getCategoriesForBudget(budget.id);
              final budgetToUndo = budget;
              await ref.read(budgetRepositoryProvider).delete(budget.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget "${budget.name}" deleted.', style: const TextStyle(fontFamily: 'PublicSans')),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () async {
                        await ref.read(budgetRepositoryProvider).update(
                          budgetToUndo.copyWith(deletedAt: null),
                          categoriesToUndo,
                        );
                      },
                    ),
                  ),
                );
              }
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

  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _CreateBudgetFormSheet(budgetToEdit: budget),
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
        final periodLabel = summary.budget.period == BudgetPeriod.monthly
            ? DateFormat('MMMM').format(summary.budget.startDate)
            : '${DateFormat('MMM d').format(summary.budget.startDate)} - ${DateFormat('MMM d').format(summary.budget.endDate)}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: TOTAL BUDGET label + month, hero figure, spent/remaining line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL BUDGET', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
                Text(periodLabel, style: TextStyle(fontFamily: 'PublicSans', color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            MoneyText(
              amountMinor: summary.totalLimitMinor,
              muteDecimals: true,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Spent: ', style: TextStyle(fontFamily: 'PublicSans', color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                MoneyText(amountMinor: summary.totalSpentMinor, style: TextStyle(fontFamily: 'IBMPlexMono', color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(width: 16),
                Text('Remaining: ', style: TextStyle(fontFamily: 'PublicSans', color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                MoneyText(amountMinor: summary.remainingMinor.abs(), style: TextStyle(fontFamily: 'IBMPlexMono', color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
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
                      backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                      child: Icon(mapCategoryIcon(iconKey), size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                                style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 0.5),
                              ),
                              Row(
                                children: [
                                  Text('/ ', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                  MoneyText(amountMinor: cat.limitMinor, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
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
                                      backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
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
                                backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          if (!isPaidFixed) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('₱0', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                                Text(
                                  catOverspent ? 'Over budget' : '${NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(cat.remainingMinor / 100)} left',
                                  style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: catOverspent ? AppTheme.inkRed : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
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
  final Budget? budgetToEdit;
  const _CreateBudgetFormSheet({this.budgetToEdit});

  @override
  ConsumerState<_CreateBudgetFormSheet> createState() => _CreateBudgetFormSheetState();
}

class _CreateBudgetFormSheetState extends ConsumerState<_CreateBudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalBudgetController = TextEditingController();
  final Map<String, TextEditingController> _limitControllers = {};

  BudgetPeriod _period = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _rollover = false;

  @override
  void initState() {
    super.initState();
    _totalBudgetController.addListener(() {
      setState(() {});
    });
    if (widget.budgetToEdit != null) {
      _nameController.text = widget.budgetToEdit!.name;
      _totalBudgetController.text = (widget.budgetToEdit!.limitMinor != null
          ? widget.budgetToEdit!.limitMinor! / 100
          : 0.0).toStringAsFixed(2);
      _period = widget.budgetToEdit!.period;
      _startDate = widget.budgetToEdit!.startDate;
      _endDate = widget.budgetToEdit!.endDate;
      _rollover = widget.budgetToEdit!.rolloverEnabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalBudgetController.dispose();
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
        if (_period == BudgetPeriod.monthly) {
          _endDate = DateTime(picked.year, picked.month + 1, picked.day);
        } else if (_period == BudgetPeriod.weekly) {
          _endDate = picked.add(const Duration(days: 7));
        }
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
    final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0.0;

    double allocatedSum = 0.0;
    for (final cat in expenseCategories) {
      final ctrl = _limitControllers[cat.id];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        allocatedSum += double.tryParse(ctrl.text) ?? 0.0;
      }
    }

    if (allocatedSum > totalBudget) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total allocated (₱${allocatedSum.toStringAsFixed(2)}) exceeds total budget of ₱${totalBudget.toStringAsFixed(2)}.')),
      );
      return;
    }

    final budgetId = DateTime.now().millisecondsSinceEpoch.toString();

    final budget = Budget(
      id: budgetId,
      name: name,
      limitMinor: (totalBudget * 100).round(),
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

    if (widget.budgetToEdit != null) {
      await ref.read(budgetRepositoryProvider).update(budget, budgetCategories);
    } else {
      await ref.read(budgetRepositoryProvider).create(budget, budgetCategories);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final allCategories = categoriesAsync.value ?? [];
    final expenseCategories = allCategories.where((c) => c.categoryType == CategoryType.expense).toList();

    for (final cat in expenseCategories) {
      _limitControllers.putIfAbsent(cat.id, () {
        final ctrl = TextEditingController();
        ctrl.addListener(() => setState(() {}));
        return ctrl;
      });
    }

    if (widget.budgetToEdit != null) {
      final limitsAsync = ref.watch(budgetCategoryLimitsProvider(widget.budgetToEdit!.id));
      final limits = limitsAsync.value;
      if (limits != null) {
        for (final limit in limits) {
          final ctrl = _limitControllers[limit.categoryId];
          if (ctrl != null && ctrl.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctrl.text.isEmpty && mounted) {
                ctrl.text = (limit.limitMinor / 100).toStringAsFixed(2);
              }
            });
          }
        }
      }
    }

    final double totalBudget = double.tryParse(_totalBudgetController.text) ?? 0.0;
    double allocatedSum = 0.0;
    _limitControllers.forEach((key, ctrl) {
      if (ctrl.text.trim().isNotEmpty) {
        allocatedSum += double.tryParse(ctrl.text) ?? 0.0;
      }
    });
    final double remainingBudget = totalBudget - allocatedSum;

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
              TextFormField(
                controller: _totalBudgetController,
                decoration: const InputDecoration(
                  labelText: 'Total Budget Limit',
                  hintText: '0.00',
                  prefixText: '₱ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontFamily: 'IBMPlexMono'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Total budget is required';
                  }
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Total budget must be greater than ₱0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetPeriod>(
                initialValue: _period,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(value: BudgetPeriod.weekly, child: Text('Weekly', style: TextStyle(fontFamily: 'PublicSans'))),
                  DropdownMenuItem(value: BudgetPeriod.monthly, child: Text('Monthly', style: TextStyle(fontFamily: 'PublicSans'))),
                  DropdownMenuItem(value: BudgetPeriod.custom, child: Text('Custom Range', style: TextStyle(fontFamily: 'PublicSans'))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _period = val;
                      if (val == BudgetPeriod.monthly) {
                        _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
                      } else if (val == BudgetPeriod.weekly) {
                        _endDate = _startDate.add(const Duration(days: 7));
                      }
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
                      title: Text('Start Date', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      subtitle: Text(_startDate.toString().substring(0, 10), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14)),
                      trailing: const Icon(Icons.calendar_today, size: 16),
                      onTap: () => _selectStartDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('End Date', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
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
                activeThumbColor: Theme.of(context).colorScheme.primary,
                title: const Text('Enable Rollover', style: TextStyle(fontFamily: 'PublicSans')),
                subtitle: const Text('Remaining amounts rollover to next period.', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11)),
                onChanged: (val) => setState(() => _rollover = val),
              ),
              const Divider(),
              if (totalBudget > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: remainingBudget >= 0 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                        : AppTheme.inkRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Allocated: ₱${allocatedSum.toStringAsFixed(2)} / ₱${totalBudget.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: remainingBudget >= 0 ? Theme.of(context).colorScheme.onSurface : AppTheme.inkRed,
                        ),
                      ),
                      Text(
                        remainingBudget >= 0 
                            ? 'Remaining: ₱${remainingBudget.toStringAsFixed(2)}'
                            : 'Over: ₱${remainingBudget.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: remainingBudget >= 0 ? AppTheme.registerGreen : AppTheme.inkRed,
                        ),
                      ),
                    ],
                  ),
                ),
                if (remainingBudget < 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.inkRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.inkRed.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.inkRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Allocated limits exceed Total Budget by ₱${remainingBudget.abs().toStringAsFixed(2)}.',
                            style: const TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.inkRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CATEGORY LIMITS',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'OPTIONAL',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(hintText: '0.00', prefixText: '₱ '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontFamily: 'IBMPlexMono'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed < 0) return 'Limit must be non-negative';

                            final totalVal = double.tryParse(_totalBudgetController.text) ?? 0.0;
                            if (totalVal <= 0) {
                              return 'Set a total budget first';
                            }

                            // Sum of all other categories
                            double otherSum = 0.0;
                            _limitControllers.forEach((k, ctrl) {
                              if (k != cat.id && ctrl.text.trim().isNotEmpty) {
                                otherSum += double.tryParse(ctrl.text) ?? 0.0;
                              }
                            });

                            if (otherSum + parsed > totalVal) {
                              final remainingForThis = totalVal - otherSum;
                              return 'Max allowed: ₱${remainingForThis.clamp(0.0, totalVal).toStringAsFixed(2)}';
                            }
                            return null;
                          },
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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