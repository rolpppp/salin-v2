import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/presentation/providers/contact_providers.dart';
import '../../../debts/domain/entities/debt.dart';
import '../../../debts/presentation/providers/debt_providers.dart';
import '../../domain/entities/split.dart';
import '../../domain/entities/split_participant.dart';
import '../providers/split_providers.dart';

class SplitsDebtsPage extends ConsumerWidget {
  const SplitsDebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplitsAsync = ref.watch(activeSplitsListProvider);
    final activeDebtsAsync = ref.watch(activeDebtsListProvider);
    final contacts = ref.watch(contactsListProvider).value ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shared Finances'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Group Splits'),
              Tab(text: 'Personal Loans'),
            ],
            labelStyle: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddActionSheet(context, ref, contacts),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Splits (Group Splits)
            activeSplitsAsync.when(
              data: (splits) {
                if (splits.isEmpty) {
                  return EmptyState(
                    message: 'No active shared splits.',
                    actionLabel: 'Create Split',
                    onAction: () => _showCreateSplitDialog(context, ref, contacts),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: splits.length,
                  itemBuilder: (context, index) {
                    final split = splits[index];
                    final balanceAsync = ref.watch(splitRemainingBalanceProvider(split.id));

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      split.title,
                                      style: const TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Shared Group Split',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Split',
                                    style: TextStyle(
                                      fontFamily: 'PublicSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'REMAINING',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    balanceAsync.when(
                                      data: (balance) => MoneyText(
                                        amountMinor: balance,
                                        style: const TextStyle(
                                          fontFamily: 'IBMPlexMono',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3F7D58),
                                        ),
                                      ),
                                      loading: () => const SizedBox(),
                                      error: (e, s) => const SizedBox(),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'ORIGINAL',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${(split.totalMinor / 100).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'IBMPlexMono',
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            balanceAsync.when(
                              data: (balance) {
                                final paid = split.totalMinor - balance;
                                final pct = split.totalMinor > 0 ? (paid / split.totalMinor) : 0.0;
                                return Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: Colors.grey.withOpacity(0.1),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3F7D58)),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Paid: ₱${(paid / 100).toStringAsFixed(2)}',
                                          style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          '${(pct * 100).round()}% Settled',
                                          style: const TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (e, s) => const SizedBox(),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _recordSplitRepayment(context, ref, split, contacts),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text(
                                    'SETTLE SHARE',
                                    style: TextStyle(
                                      fontFamily: 'PublicSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingState(),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            // Tab 2: Debts (Personal Loans)
            activeDebtsAsync.when(
              data: (debts) {
                if (debts.isEmpty) {
                  return EmptyState(
                    message: 'No active personal loans.',
                    actionLabel: 'Record Loan',
                    onAction: () => _showCreateDebtDialog(context, ref, contacts),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: debts.length,
                  itemBuilder: (context, index) {
                    final debt = debts[index];
                    final balanceAsync = ref.watch(debtRemainingBalanceProvider(debt.id));
                    final contact = contacts.firstWhere((c) => c.id == debt.contactId,
                        orElse: () => Contact(
                              id: debt.contactId,
                              name: 'Unknown',
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              syncStatus: SyncStatus.localOnly,
                            ));

                    final color = debt.isLent ? const Color(0xFF8C6A3F) : const Color(0xFFA83232);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      debt.isLent ? 'Lent to ${contact.name}' : 'Borrowed from ${contact.name}',
                                      style: const TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (debt.note != null && debt.note!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          debt.note!,
                                          style: const TextStyle(
                                            fontFamily: 'PublicSans',
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    debt.isLent ? 'Lent' : 'Borrowed',
                                    style: TextStyle(
                                      fontFamily: 'PublicSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'REMAINING',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    balanceAsync.when(
                                      data: (balance) => MoneyText(
                                        amountMinor: balance,
                                        style: TextStyle(
                                          fontFamily: 'IBMPlexMono',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      loading: () => const SizedBox(),
                                      error: (e, s) => const SizedBox(),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'ORIGINAL',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${(debt.principalMinor / 100).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'IBMPlexMono',
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            balanceAsync.when(
                              data: (balance) {
                                final paid = debt.principalMinor - balance;
                                final pct = debt.principalMinor > 0 ? (paid / debt.principalMinor) : 0.0;
                                return Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: Colors.grey.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Settled: ₱${(paid / 100).toStringAsFixed(2)}',
                                          style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          '${(pct * 100).round()}% Settled',
                                          style: const TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (e, s) => const SizedBox(),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _recordDebtRepayment(context, ref, debt),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(
                                    'SETTLE BALANCE',
                                    style: TextStyle(
                                      fontFamily: 'PublicSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  void _showAddActionSheet(BuildContext context, WidgetRef ref, List<Contact> contacts) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Shared Split', style: TextStyle(fontFamily: 'PublicSans')),
              onTap: () {
                Navigator.pop(context);
                _showCreateSplitDialog(context, ref, contacts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.handshake),
              title: const Text('Record Personal Loan (Debt)', style: TextStyle(fontFamily: 'PublicSans')),
              onTap: () {
                Navigator.pop(context);
                _showCreateDebtDialog(context, ref, contacts);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSplitDialog(BuildContext context, WidgetRef ref, List<Contact> contacts) {
    final titleController = TextEditingController();
    final totalController = TextEditingController();
    final Map<String, TextEditingController> _shareControllers = {};

    final accounts = ref.read(accountsListProvider).value ?? [];
    if (accounts.isEmpty || contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify you have at least one Account and one Contact created.')),
      );
      return;
    }

    String selectedAccountId = accounts.first.id;

    for (final c in contacts) {
      _shareControllers[c.id] = TextEditingController();
    }

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
                  'Create Expense Split',
                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Split Title * (e.g. Dinner)'),
                  style: const TextStyle(fontFamily: 'PublicSans'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalController,
                  decoration: const InputDecoration(labelText: 'Total Bill (₱) *', prefixText: '₱ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontFamily: 'IBMPlexMono'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Paid From Account *'),
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
                const Divider(height: 24),
                const Text(
                  'PARTICIPANT SHARES',
                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                ...contacts.map((c) {
                  final ctrl = _shareControllers[c.id]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(c.name, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600))),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final totalDouble = double.tryParse(totalController.text.trim()) ?? 0.0;
                    if (totalDouble <= 0) return;

                    final splitId = DateTime.now().millisecondsSinceEpoch.toString();
                    final participants = <SplitParticipant>[];

                    for (final c in contacts) {
                      final ctrl = _shareControllers[c.id];
                      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
                        final valDouble = double.tryParse(ctrl.text.trim()) ?? 0.0;
                        if (valDouble > 0) {
                          participants.add(SplitParticipant(
                            id: "${splitId}_${c.id}",
                            splitId: splitId,
                            contactId: c.id,
                            shareMinor: (valDouble * 100).round(),
                            createdAt: DateTime.now().toUtc(),
                            updatedAt: DateTime.now().toUtc(),
                          ));
                        }
                      }
                    }

                    if (participants.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add at least one participant share.')),
                      );
                      return;
                    }

                    final splitObj = Split(
                      id: splitId,
                      title: title,
                      totalMinor: (totalDouble * 100).round(),
                      status: SplitStatus.active,
                      createdAt: DateTime.now().toUtc(),
                      updatedAt: DateTime.now().toUtc(),
                      syncStatus: SyncStatus.localOnly,
                    );

                    await ref.read(splitRepositoryProvider).createSplit(
                          splitObj,
                          participants,
                          accountId: selectedAccountId,
                          occurredAt: DateTime.now(),
                        );

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Split', style: TextStyle(fontFamily: 'PublicSans')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _recordSplitRepayment(BuildContext context, WidgetRef ref, Split split, List<Contact> contacts) async {
    final accounts = ref.read(accountsListProvider).value ?? [];
    final participants = await ref.read(splitRepositoryProvider).getParticipantsForSplit(split.id);

    if (accounts.isEmpty || participants.isEmpty) return;

    String selectedAccountId = accounts.first.id;
    String selectedParticipantId = participants.first.contactId;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Split Repayment', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedParticipantId,
                decoration: const InputDecoration(labelText: 'From Friend'),
                items: participants.map((p) {
                  final c = contacts.firstWhere((contact) => contact.id == p.contactId,
                      orElse: () => Contact(id: p.contactId, name: 'Friend', createdAt: DateTime.now(), updatedAt: DateTime.now(), syncStatus: SyncStatus.localOnly));
                  return DropdownMenuItem(value: p.contactId, child: Text(c.name, style: const TextStyle(fontFamily: 'PublicSans')));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedParticipantId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount Paid (₱) *', prefixText: '₱ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontFamily: 'IBMPlexMono'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedAccountId,
                decoration: const InputDecoration(labelText: 'Deposit Account *'),
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
              final doubleAmt = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (doubleAmt <= 0) return;

              final friend = contacts.firstWhere((c) => c.id == selectedParticipantId);

              await ref.read(splitRepositoryProvider).recordRepayment(
                    split.id,
                    selectedParticipantId,
                    selectedAccountId,
                    (doubleAmt * 100).round(),
                    DateTime.now(),
                    'Repayment from ${friend.name} for ${split.title}',
                  );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Record', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }

  void _showCreateDebtDialog(BuildContext context, WidgetRef ref, List<Contact> contacts) {
    final principalController = TextEditingController();
    final noteController = TextEditingController();

    final accounts = ref.read(accountsListProvider).value ?? [];
    if (accounts.isEmpty || contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create an Account and a Contact first.')),
      );
      return;
    }

    String selectedAccountId = accounts.first.id;
    String selectedContactId = contacts.first.id;
    bool isLent = true;

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
                  'Record Personal Loan',
                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedContactId,
                  decoration: const InputDecoration(labelText: 'Friend / Contact *'),
                  items: contacts.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontFamily: 'PublicSans')));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedContactId = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool>(
                  initialValue: isLent,
                  decoration: const InputDecoration(labelText: 'Type *'),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Lent money (Owed to you)', style: TextStyle(fontFamily: 'PublicSans'))),
                    DropdownMenuItem(value: false, child: Text('Borrowed money (Owed by you)', style: TextStyle(fontFamily: 'PublicSans'))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        isLent = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: principalController,
                  decoration: const InputDecoration(labelText: 'Principal Amount (₱) *', prefixText: '₱ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontFamily: 'IBMPlexMono'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Funding Account *'),
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
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note (e.g. concert ticket)'),
                  style: const TextStyle(fontFamily: 'PublicSans'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final doubleAmt = double.tryParse(principalController.text.trim()) ?? 0.0;
                    if (doubleAmt <= 0) return;

                    final debtId = DateTime.now().millisecondsSinceEpoch.toString();

                    final debtObj = Debt(
                      id: debtId,
                      contactId: selectedContactId,
                      isLent: isLent,
                      principalMinor: (doubleAmt * 100).round(),
                      status: DebtStatus.active,
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                      createdAt: DateTime.now().toUtc(),
                      updatedAt: DateTime.now().toUtc(),
                      syncStatus: SyncStatus.localOnly,
                    );

                    await ref.read(debtRepositoryProvider).createDebt(
                          debtObj,
                          isLent: isLent,
                          accountId: selectedAccountId,
                          occurredAt: DateTime.now(),
                        );

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Loan', style: TextStyle(fontFamily: 'PublicSans')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _recordDebtRepayment(BuildContext context, WidgetRef ref, Debt debt) async {
    final accounts = ref.read(accountsListProvider).value ?? [];
    if (accounts.isEmpty) return;

    String selectedAccountId = accounts.first.id;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(debt.isLent ? 'Record Payment Received' : 'Record Payment Paid', style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount Paid (₱) *', prefixText: '₱ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontFamily: 'IBMPlexMono'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedAccountId,
                decoration: const InputDecoration(labelText: 'Account *'),
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
              final doubleAmt = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (doubleAmt <= 0) return;

              await ref.read(debtRepositoryProvider).recordRepayment(
                    debt.id,
                    selectedAccountId,
                    (doubleAmt * 100).round(),
                    DateTime.now(),
                    debt.isLent ? 'Repayment received' : 'Repayment paid',
                  );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }
}
