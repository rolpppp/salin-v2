import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/hero_receipt_card.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/account.dart';
import '../providers/account_providers.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.monetization_on_outlined;
      case AccountType.bank:
        return Icons.account_balance_outlined;
      case AccountType.savings:
        return Icons.savings_outlined;
      case AccountType.eWallet:
        return Icons.account_balance_wallet_outlined;
      case AccountType.creditCard:
        return Icons.credit_card_outlined;
      case AccountType.debitCard:
        return Icons.payment_outlined;
      case AccountType.investment:
        return Icons.trending_up_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateAccountDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Balance Card
            totalBalanceAsync.when(
              data: (total) => HeroReceiptCard(
                title: "Total Balance",
                amountMinor: total,
                subtitle: "Total cash across all accounts",
              ),
              loading: () => const LoadingState(),
              error: (err, stack) => HeroReceiptCard(
                title: "Total Balance",
                amountMinor: 0,
                subtitle: "Error calculating balance",
              ),
            ),
            
            const SizedBox(height: 24),
            
            const SectionHeader(title: "All Accounts"),
            
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return EmptyState(
                    message: "No financial accounts created yet.",
                    actionLabel: "Create Account",
                    onAction: () => _showCreateAccountDialog(context, ref),
                  );
                }
                return Column(
                  children: accounts.map((account) {
                    final balanceAsync = ref.watch(accountBalanceProvider(account.id));
                    return balanceAsync.when(
                      data: (balance) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Icon(_getAccountIcon(account.accountType), color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'PublicSans')),
                          subtitle: Text(account.accountType.name.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                          trailing: MoneyText(
                            amountMinor: balance,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(height: 72),
                      error: (err, stack) => const SizedBox(height: 72),
                    );
                  }).toList(),
                );
              },
              loading: () => const LoadingState(),
              error: (err, stack) => Text("Error: $err"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    AccountType selectedType = AccountType.cash;
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Account', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                      ),
                      style: const TextStyle(fontFamily: 'PublicSans'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AccountType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                      ),
                      items: AccountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase(), style: const TextStyle(fontFamily: 'PublicSans')),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(
                        labelText: 'Initial Balance (₱)',
                        hintText: '0.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontFamily: 'IBMPlexMono'),
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
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final balanceDouble = double.tryParse(balanceController.text) ?? 0.0;
                    final balanceMinor = (balanceDouble * 100).round();

                    final newAccount = Account(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      accountType: selectedType,
                      openingBalanceMinor: balanceMinor,
                      currency: 'PHP',
                      icon: 'default_icon',
                      color: null,
                      displayOrder: DateTime.now().millisecondsSinceEpoch,
                      isArchived: false,
                      createdAt: DateTime.now().toUtc(),
                      updatedAt: DateTime.now().toUtc(),
                      syncStatus: SyncStatus.localOnly,
                    );

                    await ref.read(accountRepositoryProvider).create(newAccount);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(fontFamily: 'PublicSans')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
