import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/financial_enums.dart';
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
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateBudgetDialog(context, ref),
          ),
        ],
      ),
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
            padding: const EdgeInsets.all(16.0),
            children: [
              if (activeBudget != null) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'ACTIVE BUDGET',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _ActiveBudgetCard(budgetId: activeBudget.id),
                const SizedBox(height: 24),
              ],
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'ALL BUDGETS',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                    ),
                  ),
                ),
              Card(
                child: Column(
                  children: budgets.map((b) {
                    final isCurrent = activeBudget?.id == b.id;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            b.name,
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
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
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(budgetRepositoryProvider).delete(budget.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _CreateBudgetFormSheet(),
    );
  }
}

class _ActiveBudgetCard extends ConsumerWidget {
  final String budgetId;

  const _ActiveBudgetCard({required this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(budgetSummaryProvider(budgetId));

    return summaryAsync.when(
      data: (summary) {
        final progress = summary.progress;
        final isOverspent = summary.isOverspent;

        Color progressColor = Colors.green;
        if (progress > 0.8 && progress <= 1.0) {
          progressColor = Colors.amber;
        } else if (isOverspent) {
          progressColor = Colors.red;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          summary.budget.name,
                          style: const TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isOverspent ? 'EXCEEDED' : '${(progress * 100).toStringAsFixed(0)}% Spent',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Spent', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Colors.grey)),
                            MoneyText(
                              amountMinor: summary.totalSpentMinor,
                              style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(isOverspent ? 'Over budget' : 'Remaining', style: const TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Colors.grey)),
                            MoneyText(
                              amountMinor: summary.remainingMinor.abs(),
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isOverspent ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'CATEGORIES',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summary.categorySummaries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = summary.categorySummaries[index];
                  final catProgress = cat.progress;
                  final catOverspent = cat.isOverspent;

                  Color catColor = Colors.green;
                  if (catProgress > 0.8 && catProgress <= 1.0) {
                    catColor = Colors.amber;
                  } else if (catOverspent) {
                    catColor = Colors.red;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.categoryName,
                              style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                MoneyText(
                                  amountMinor: cat.spentMinor,
                                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ' / ',
                                  style: TextStyle(color: Colors.grey.withOpacity(0.5)),
                                ),
                                MoneyText(
                                  amountMinor: cat.limitMinor,
                                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: catProgress > 1.0 ? 1.0 : catProgress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(catColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_period == BudgetPeriod.monthly) {
          _endDate = DateTime(picked.year, picked.month + 1, picked.day);
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign a limit to at least one category.')),
      );
      return;
    }

    await ref.read(budgetRepositoryProvider).create(budget, budgetCategories);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final allCategories = categoriesAsync.value ?? [];
    final expenseCategories = allCategories.where((c) => c.categoryType == CategoryType.expense).toList();

    // Initialize text controllers for category limits
    for (final cat in expenseCategories) {
      _limitControllers.putIfAbsent(cat.id, () => TextEditingController());
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Budget',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Budget Name',
                  hintText: 'e.g. July 2026',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetPeriod>(
                initialValue: _period,
                decoration: const InputDecoration(
                  labelText: 'Period',
                ),
                items: const [
                  DropdownMenuItem(value: BudgetPeriod.monthly, child: Text('Monthly', style: TextStyle(fontFamily: 'PublicSans'))),
                  DropdownMenuItem(value: BudgetPeriod.custom, child: Text('Custom Range', style: TextStyle(fontFamily: 'PublicSans'))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _period = val;
                      if (val == BudgetPeriod.monthly) {
                        _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
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
                      title: const Text('Start Date', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        _startDate.toString().substring(0, 10),
                        style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_today, size: 16),
                      onTap: () => _selectStartDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        _endDate.toString().substring(0, 10),
                        style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14),
                      ),
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
                title: const Text('Enable Rollover', style: TextStyle(fontFamily: 'PublicSans')),
                subtitle: const Text('Remaining amounts rollover to next period.', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11)),
                onChanged: (val) {
                  setState(() {
                    _rollover = val;
                  });
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'CATEGORY LIMITS',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...expenseCategories.map((cat) {
                final ctrl = _limitControllers[cat.id]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(cat.name, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '₱ ',
                          ),
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
