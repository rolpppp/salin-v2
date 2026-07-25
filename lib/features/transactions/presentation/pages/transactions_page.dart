import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../providers/transaction_providers.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_providers.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerEntriesAsync = ref.watch(ledgerEntriesListProvider);
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/add'),
          ),
        ],
      ),
      body: ledgerEntriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              message: "No ledger transactions recorded yet.",
              actionLabel: "Add Transaction",
              onAction: () => context.go('/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isExpense = entry.direction == MoneyDirection.outflow;

              // Find account name
              final accounts = accountsAsync.value ?? [];
              final account = accounts.firstWhere(
                (a) => a.id == entry.accountId,
                orElse: () => Account(
                  id: '',
                  name: 'Unknown',
                  accountType: AccountType.cash,
                  openingBalanceMinor: 0,
                  currency: 'PHP',
                  icon: '',
                  displayOrder: 0,
                  isArchived: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  syncStatus: SyncStatus.localOnly,
                ),
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
                    child: Icon(
                      isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    entry.note != null && entry.note!.isNotEmpty
                        ? entry.note!
                        : (isExpense ? 'Expense' : 'Income'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'PublicSans'),
                  ),
                  subtitle: Text(
                    "${account.name} • ${entry.occurredAt.toLocal().toString().substring(0, 16)}",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoneyText(
                        amountMinor: entry.amountMinor,
                        isNegative: isExpense,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isExpense ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDelete(context, ref, entry.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this ledger transaction? This will update account balances.', style: TextStyle(fontFamily: 'PublicSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(transactionRepositoryProvider).deleteLedgerEntry(id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
