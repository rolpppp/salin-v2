import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

                // Find next deduction date
                final earliest = pending.isNotEmpty ? pending.first.scheduledDate : null;
                final nextDeductionText = earliest != null ? _formatMonthDay(earliest) : 'NONE';

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
                                const Text(
                                  'TOTAL UPCOMING',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Colors.grey,
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
                                const Text(
                                  'NEXT DEDUCTION',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Colors.grey,
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
                      _buildSectionHeader('UPCOMING', Colors.grey),
                      ...upcoming.map((inst) => _buildCommitmentTile(context, ref, inst, rules, Colors.grey)),
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
                    return ListTile(
                      title: Text(rule.title, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Every ${rule.interval} ${rule.frequency.name}(s) • Starting ${rule.startDate.toLocal().toString().substring(0, 10)}',
                        style: const TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MoneyText(
                            amountMinor: rule.amountMinor,
                            style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => ref.read(recurringRepositoryProvider).deleteRule(rule.id),
                          ),
                        ],
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
                  'Due ${_formatMonthDay(inst.scheduledDate)}',
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
                      'MARK PAID',
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
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
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
    final accounts = ref.read(accountsListProvider).value ?? [];
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
                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
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
              await ref.read(recurringRepositoryProvider).markAsPaid(inst.id, selectedAccountId, DateTime.now());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final intervalController = TextEditingController(text: '1');

    final accounts = ref.read(accountsListProvider).value ?? [];
    final categories = ref.read(categoriesListProvider).value ?? [];

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create an account first.')),
      );
      return;
    }

    String selectedAccountId = accounts.first.id;
    String? selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
    RecurringFrequency frequency = RecurringFrequency.monthly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                const Text(
                  'Add Recurring Schedule',
                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 18, fontWeight: FontWeight.bold),
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
                    ...categories.map((cat) {
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
                      ),
                    ),
                  ],
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

                    final rule = RecurringRule(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      accountId: selectedAccountId,
                      categoryId: selectedCategoryId,
                      amountMinor: (amountDouble * 100).round(),
                      direction: MoneyDirection.outflow,
                      frequency: frequency,
                      interval: interval,
                      startDate: DateTime.now().toUtc(),
                      autoGenerate: true,
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                      createdAt: DateTime.now().toUtc(),
                      updatedAt: DateTime.now().toUtc(),
                      syncStatus: SyncStatus.localOnly,
                    );

                    await ref.read(recurringRepositoryProvider).createRule(rule);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Schedule', style: TextStyle(fontFamily: 'PublicSans')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
