import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/recurring_providers.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/entities/recurring_instance.dart';

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instancesAsync = ref.watch(upcomingInstancesListProvider);
    final rulesAsync = ref.watch(recurringRulesListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddRuleDialog(context, ref),
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add, size: 28),
        ),
        appBar: AppBar(
          title: const Text('Recurring'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Commitments'),
              Tab(text: 'Schedules & Rules'),
            ],
            labelStyle: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddRuleDialog(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Commitments (Mockup-inspired)
            instancesAsync.when(
              data: (instances) {
                final pending = instances.where((i) => i.status == RecurringInstanceStatus.pending).toList();
                final rules = rulesAsync.value ?? [];

                if (pending.isEmpty) {
                  return const EmptyState(
                    message: 'No active scheduled commitments.',
                  );
                }

                // Calculate total upcoming sum
                int totalUpcomingMinor = 0;
                for (final inst in pending) {
                  final r = rules.firstWhere((rule) => rule.id == inst.recurringRuleId, orElse: () => _dummyRule(inst.recurringRuleId));
                  totalUpcomingMinor += r.amountMinor;
                }

                // Find next deduction / income date
                final earliest = pending.isNotEmpty ? pending.first : null;
                final nextRule = earliest != null 
                    ? rules.firstWhere((r) => r.id == earliest.recurringRuleId, orElse: () => _dummyRule(earliest.recurringRuleId))
                    : null;
                final isNextIncome = nextRule?.direction == MoneyDirection.inflow;
                final nextDeductionText = earliest != null ? _formatMonthDay(earliest.scheduledDate) : 'NONE';

                // Categorize instances
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayEnd = todayStart.add(const Duration(days: 1));

                final overdue = <RecurringInstance>[];
                final dueToday = <RecurringInstance>[];
                final upcoming = <RecurringInstance>[];

                for (final inst in pending) {
                  if (inst.scheduledDate.isBefore(todayStart)) {
                    overdue.add(inst);
                  } else if (inst.scheduledDate.isBefore(todayEnd)) {
                    dueToday.add(inst);
                  } else {
                    upcoming.add(inst);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Metric Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL UPCOMING',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: AppTheme.carbonText.withOpacity(0.5),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                MoneyText(
                                  amountMinor: totalUpcomingMinor,
                                  style: const TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNextIncome ? 'NEXT INCOME' : 'NEXT DEDUCTION',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: AppTheme.carbonText.withOpacity(0.5),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nextDeductionText,
                                  style: const TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Overdue Section
                    if (overdue.isNotEmpty) ...[
                      _buildSectionHeader('OVERDUE', const Color(0xFFA83232)),
                      ...overdue.map((inst) => _buildCommitmentTile(context, ref, inst, rules, const Color(0xFFA83232))),
                      const SizedBox(height: 24),
                    ],

                    // Due Today Section
                    if (dueToday.isNotEmpty) ...[
                      _buildSectionHeader('DUE TODAY', const Color(0xFF8C6A3F)),
                      ...dueToday.map((inst) => _buildCommitmentTile(context, ref, inst, rules, const Color(0xFF8C6A3F))),
                      const SizedBox(height: 24),
                    ],

                    // Upcoming Section
                    if (upcoming.isNotEmpty) ...[
                      _buildSectionHeader('UPCOMING', AppTheme.carbonText.withOpacity(0.5)),
                      ...upcoming.map((inst) => _buildCommitmentTile(context, ref, inst, rules, AppTheme.carbonText.withOpacity(0.5))),
                      const SizedBox(height: 24),
                    ],
                  ],
                );
              },
              loading: () => const LoadingState(),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            // Tab 2: Rules / Settings
            rulesAsync.when(
              data: (rules) {
                if (rules.isEmpty) {
                  return EmptyState(
                    message: 'No recurring rules set up.',
                    actionLabel: 'Add Schedule',
                    onAction: () => _showAddRuleDialog(context, ref),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: rules.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    return Dismissible(
                      key: Key(rule.id),
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
                          _showAddRuleDialog(context, ref, existingRule: rule);
                          return false;
                        } else {
                          bool deleteConfirmed = false;
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Schedule', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
                              content: const Text('Are you sure you want to delete this recurring schedule? Upcoming unpaid commitments will be cancelled.', style: TextStyle(fontFamily: 'PublicSans')),
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
                            await ref.read(recurringRepositoryProvider).deleteRule(rule.id);
                            return true;
                          }
                          return false;
                        }
                      },
                      child: ListTile(
                        title: Text(rule.title, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Every ${rule.interval} ${rule.frequency.name}(s) • Starting ${rule.startDate.toLocal().toString().substring(0, 10)}',
                          style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: AppTheme.carbonText.withOpacity(0.5)),
                        ),
                        trailing: MoneyText(
                          amountMinor: rule.amountMinor,
                          style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingState(),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentTile(BuildContext context, WidgetRef ref, RecurringInstance inst, List<RecurringRule> rules, Color statusColor) {
    final rule = rules.firstWhere((r) => r.id == inst.recurringRuleId, orElse: () => _dummyRule(inst.recurringRuleId));
    final iconData = _getIconForTitle(rule.title);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Icon(iconData, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Title / Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rule.direction == MoneyDirection.inflow ? 'Expected' : 'Due'} ${_formatMonthDay(inst.scheduledDate)}',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          // Amount / Mark Paid
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                amountMinor: rule.amountMinor,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _markPaidFlow(context, ref, inst, rule),
                    child: Text(
                      '${rule.direction == MoneyDirection.inflow ? 'RECEIVED' : 'PAID'}',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(recurringRepositoryProvider).skipOccurrence(inst.id),
                    child: Text(
                      'SKIP',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.carbonText.withOpacity(0.5),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  RecurringRule _dummyRule(String id) {
    return RecurringRule(
      id: id,
      title: 'Subscription',
      accountId: '',
      amountMinor: 0,
      direction: MoneyDirection.outflow,
      frequency: RecurringFrequency.monthly,
      interval: 1,
      startDate: DateTime.now(),
      autoGenerate: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.localOnly,
    );
  }

  String _formatMonthDay(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('water') || t.contains('utility') || t.contains('electric') || t.contains('bill')) {
      return Icons.water_drop_outlined;
    }
    if (t.contains('rent') || t.contains('home') || t.contains('house') || t.contains('room')) {
      return Icons.home_outlined;
    }
    if (t.contains('music') || t.contains('spotify') || t.contains('sound')) {
      return Icons.music_note_outlined;
    }
    if (t.contains('netflix') || t.contains('movie') || t.contains('video') || t.contains('stream')) {
      return Icons.movie_outlined;
    }
    if (t.contains('fit') || t.contains('gym') || t.contains('workout') || t.contains('health')) {
      return Icons.fitness_center_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  void _markPaidFlow(BuildContext context, WidgetRef ref, RecurringInstance inst, RecurringRule rule) async {
    final accounts = (ref.read(accountsListProvider).value ?? []).where((a) => !a.isArchived).toList();
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create an account first.')),
      );
      return;
    }

    String selectedAccountId = rule.accountId.isNotEmpty && accounts.any((a) => a.id == rule.accountId)
        ? rule.accountId
        : accounts.first.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Mark "${rule.title}" as paid? This records an outflow expense of:', style: const TextStyle(fontFamily: 'PublicSans')),
              const SizedBox(height: 12),
              Center(
                child: MoneyText(
                  amountMinor: rule.amountMinor,
                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.inkRed),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAccountId,
                decoration: const InputDecoration(labelText: 'Pay from Account'),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text(acc.name, style: const TextStyle(fontFamily: 'PublicSans')),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedAccountId = val;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(recurringRepositoryProvider);
              await repo.markAsPaid(inst.id, selectedAccountId, DateTime.now());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref, {RecurringRule? existingRule}) {
    final titleController = TextEditingController(text: existingRule?.title);
    final amountController = TextEditingController(
      text: existingRule != null ? (existingRule.amountMinor / 100).toStringAsFixed(2) : '',
    );
    final noteController = TextEditingController(text: existingRule?.note ?? '');
    final intervalController = TextEditingController(text: existingRule?.interval.toString() ?? '1');

    final accounts = (ref.read(accountsListProvider).value ?? []).where((a) => !a.isArchived).toList();
    final categories = ref.read(categoriesListProvider).value ?? [];

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create an account first.')),
      );
      return;
    }

    String selectedAccountId = existingRule?.accountId ?? accounts.first.id;
    if (!accounts.any((a) => a.id == selectedAccountId)) {
      selectedAccountId = accounts.first.id;
    }
    String? selectedCategoryId = existingRule?.categoryId;
    RecurringFrequency frequency = existingRule?.frequency ?? RecurringFrequency.monthly;
    DateTime? selectedEndDate = existingRule?.endDate;
    bool isIncome = existingRule?.direction == MoneyDirection.inflow;
    DateTime selectedStartDate = existingRule?.startDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) => StatefulBuilder(
          builder: (context, setState) {
            String getExplanation() {
              final freqName = frequency.name.toLowerCase();
              final intervalVal = int.tryParse(intervalController.text.trim()) ?? 1;
              String repStr = '';
              if (intervalVal == 1) {
                if (frequency == RecurringFrequency.monthly) repStr = 'monthly';
                else if (frequency == RecurringFrequency.weekly) repStr = 'weekly';
                else if (frequency == RecurringFrequency.daily) repStr = 'daily';
                else if (frequency == RecurringFrequency.yearly) repStr = 'yearly';
                else repStr = 'every ${frequency.name}';
              } else {
                repStr = 'every $intervalVal ${freqName}s';
              }
              final startStr = selectedStartDate.toLocal().toString().substring(0, 10);
              final endStr = selectedEndDate != null 
                  ? ' until ${selectedEndDate!.toLocal().toString().substring(0, 10)}' 
                  : ' ongoing';
              return 'Payment will repeat $repStr starting $startStr,$endStr.';
            }

            final filteredCats = categories.where((c) => c.categoryType == (isIncome ? CategoryType.income : CategoryType.expense)).toList();
            if (selectedCategoryId != null && !filteredCats.any((c) => c.id == selectedCategoryId)) {
              selectedCategoryId = null;
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        existingRule != null ? 'Edit Recurring Schedule' : 'Add Recurring Schedule',
                        style: const TextStyle(fontFamily: 'PublicSans', fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title * (e.g. Netflix)'),
                        style: const TextStyle(fontFamily: 'PublicSans'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount (₱) *', prefixText: '₱ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontFamily: 'IBMPlexMono'),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Income (e.g. Payroll, Dividends)', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                        value: isIncome,
                        onChanged: (val) {
                          setState(() {
                            isIncome = val;
                            selectedCategoryId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedAccountId,
                        decoration: const InputDecoration(labelText: 'Default Account *'),
                        items: accounts.map((acc) {
                          return DropdownMenuItem(value: acc.id, child: Text(acc.name, style: const TextStyle(fontFamily: 'PublicSans')));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedAccountId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Unassigned', style: TextStyle(fontFamily: 'PublicSans'))),
                          ...filteredCats.map((cat) {
                            return DropdownMenuItem(value: cat.id, child: Text(cat.name, style: const TextStyle(fontFamily: 'PublicSans')));
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedCategoryId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<RecurringFrequency>(
                              value: frequency,
                              decoration: const InputDecoration(labelText: 'Frequency'),
                              items: RecurringFrequency.values.map((f) {
                                return DropdownMenuItem(value: f, child: Text(f.name.toUpperCase(), style: const TextStyle(fontFamily: 'PublicSans', fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    frequency = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: intervalController,
                              decoration: const InputDecoration(labelText: 'Interval'),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontFamily: 'IBMPlexMono'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getExplanation(),
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start Date *', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(selectedStartDate.toLocal().toString().substring(0, 10), style: const TextStyle(fontFamily: 'IBMPlexMono')),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedStartDate = picked.toUtc();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('End Date (Optional)', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(selectedEndDate != null ? selectedEndDate!.toLocal().toString().substring(0, 10) : 'Ongoing (No End Date)', style: const TextStyle(fontFamily: 'IBMPlexMono')),
                        trailing: selectedEndDate != null 
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => setState(() => selectedEndDate = null),
                              )
                            : const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedEndDate = picked.toUtc();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(labelText: 'Note'),
                        style: const TextStyle(fontFamily: 'PublicSans'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final amountDouble = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (amountDouble <= 0) return;

                          final interval = int.tryParse(intervalController.text.trim()) ?? 1;
                          final repo = ref.read(recurringRepositoryProvider);

                          if (existingRule != null) {
                            final rule = existingRule.copyWith(
                              title: title,
                              accountId: selectedAccountId,
                              categoryId: selectedCategoryId,
                              amountMinor: (amountDouble * 100).round(),
                              direction: isIncome ? MoneyDirection.inflow : MoneyDirection.outflow,
                              frequency: frequency,
                              interval: interval,
                              startDate: selectedStartDate,
                              endDate: selectedEndDate,
                              note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                              updatedAt: DateTime.now().toUtc(),
                            );
                            await repo.updateRule(rule);
                          } else {
                            final rule = RecurringRule(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: title,
                              accountId: selectedAccountId,
                              categoryId: selectedCategoryId,
                              amountMinor: (amountDouble * 100).round(),
                              direction: isIncome ? MoneyDirection.inflow : MoneyDirection.outflow,
                              frequency: frequency,
                              interval: interval,
                              startDate: selectedStartDate,
                              endDate: selectedEndDate,
                              autoGenerate: true,
                              note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                              createdAt: DateTime.now().toUtc(),
                              updatedAt: DateTime.now().toUtc(),
                              syncStatus: SyncStatus.localOnly,
                            );
                            await repo.createRule(rule);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save Schedule', style: TextStyle(fontFamily: 'PublicSans')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
