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
import '../../domain/entities/account.dart';
import '../providers/account_providers.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_outlined;
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

  String _formatRelative(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day;
    final time = DateFormat('h:mm a').format(local);

    if (isToday) return 'Today, $time';
    if (isYesterday) return 'Yesterday, $time';
    return '${DateFormat('MMM d').format(local)}, $time';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAccountDialog(context, ref),
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
      appBar: AppBar(
        title: const Text('Net Worth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateAccountDialog(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyState(
              message: 'No financial accounts created yet.',
              actionLabel: 'Create Account',
              onAction: () => _showCreateAccountDialog(context, ref),
            );
          }

          // "MAIN" is the account with the lowest displayOrder. There's no
          // dedicated isPrimary flag on the entity yet — worth adding one if
          // account reordering becomes a feature, but this is a reasonable
          // stand-in for now.
          final sorted = [...accounts]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          final mainAccountId = sorted.first.id;
          final categories = categoriesAsync.value ?? const <Category>[];

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              // Net Worth hero
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Worth',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'PublicSans',
                            color: AppTheme.carbonText.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 6),
                    totalBalanceAsync.when(
                      data: (total) => MoneyText(
                        amountMinor: total,
                        muteDecimals: true,
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppTheme.carbonText),
                      ),
                      loading: () => const SizedBox(height: 48),
                      error: (err, stack) => const Text('—'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Horizontal compact account cards — a row of parallel peer
              // items, per the design system's density rule, not a vertical
              // stack.
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final account = sorted[index];
                    final isMain = account.id == mainAccountId;
                    final balanceAsync = ref.watch(accountBalanceProvider(account.id));
                    return GestureDetector(
                      onTap: () => _showAccountOptions(context, ref, account),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isMain ? AppTheme.oceanBlue : AppTheme.carbonText.withOpacity(0.08),
                            width: isMain ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(_getAccountIcon(account.accountType), size: 20, color: AppTheme.oceanBlue),
                                if (isMain)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.oceanBlue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'MAIN',
                                      style: TextStyle(fontFamily: 'PublicSans', fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.oceanBlue),
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'PublicSans', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.carbonText),
                            ),
                            const SizedBox(height: 2),
                            balanceAsync.when(
                              data: (balance) => MoneyText(
                                amountMinor: balance,
                                muteDecimals: true,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.carbonText),
                              ),
                              loading: () => const SizedBox(height: 18),
                              error: (err, stack) => const Text('—'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Recent Activity, grouped by account
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontFamily: 'PublicSans', fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.carbonText),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.oceanBlue, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              ...sorted.map((account) {
                final entriesAsync = ref.watch(ledgerEntriesByAccountProvider(account.id));
                return entriesAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) return const SizedBox.shrink();
                    final recent = entries.take(2).toList();
                    final isMain = account.id == mainAccountId;

                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isMain ? AppTheme.oceanBlue : AppTheme.carbonText.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(account.name, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                          ...recent.map((entry) {
                            final category = categories.where((c) => c.id == entry.categoryId).toList();
                            final isInflow = entry.direction == MoneyDirection.inflow;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.carbonText.withOpacity(0.06),
                                child: Icon(
                                  category.isNotEmpty ? mapCategoryIcon(category.first.icon) : Icons.receipt_long_outlined,
                                  size: 18,
                                  color: AppTheme.carbonText.withOpacity(0.7),
                                ),
                              ),
                              title: Text(entry.note?.isNotEmpty == true ? entry.note! : 'Transaction',
                                  style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                              subtitle: Text(_formatRelative(entry.occurredAt),
                                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, color: AppTheme.carbonText.withOpacity(0.5))),
                              trailing: MoneyText(
                                amountMinor: entry.amountMinor,
                                isNegative: !isInflow,
                                showSign: isInflow,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isInflow ? AppTheme.oceanBlue : AppTheme.carbonText,
                                ),
                              ),
                            );
                          }),

                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                );
              }),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAccountOptions(BuildContext context, WidgetRef ref, Account account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  account.name,
                  style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppTheme.oceanBlue),
                title: const Text('Edit Account', style: TextStyle(fontFamily: 'PublicSans')),
                onTap: () {
                  Navigator.pop(context);
                  _showEditAccountDialog(context, ref, account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.inkRed),
                title: const Text('Delete Account', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.inkRed)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteAccount(context, ref, account);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the account "${account.name}"? This will delete all its ledger records and cannot be undone.', style: const TextStyle(fontFamily: 'PublicSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            onPressed: () async {
              final accountToUndo = account;
              await ref.read(accountRepositoryProvider).delete(account.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account "${account.name}" deleted.', style: const TextStyle(fontFamily: 'PublicSans')),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () async {
                        await ref.read(accountRepositoryProvider).update(
                          accountToUndo.copyWith(deletedAt: null),
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

  void _showEditAccountDialog(BuildContext context, WidgetRef ref, Account account) {
    final nameController = TextEditingController(text: account.name);
    AccountType selectedType = account.accountType;
    final balanceController = TextEditingController(text: (account.openingBalanceMinor / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Account', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Account Name'),
                      style: const TextStyle(fontFamily: 'PublicSans'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AccountType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Account Type'),
                      items: AccountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase(), style: const TextStyle(fontFamily: 'PublicSans')),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(labelText: 'Initial Balance (₱)', hintText: '0.00'),
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

                    final accounts = ref.read(accountsListProvider).value ?? [];
                    final nameExists = accounts.any((a) => a.id != account.id && a.name.trim().toLowerCase() == name.toLowerCase());
                    if (nameExists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account name must be unique.')),
                      );
                      return;
                    }

                    final balanceDouble = double.tryParse(balanceController.text) ?? 0.0;
                    if (balanceDouble < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Initial balance cannot be negative.')),
                      );
                      return;
                    }

                    final balanceMinor = (balanceDouble * 100).round();

                    final updatedAccount = account.copyWith(
                      name: name,
                      accountType: selectedType,
                      openingBalanceMinor: balanceMinor,
                      updatedAt: DateTime.now().toUtc(),
                      syncStatus: SyncStatus.localOnly,
                    );

                    await ref.read(accountRepositoryProvider).update(updatedAccount);
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
                      decoration: const InputDecoration(labelText: 'Account Name'),
                      style: const TextStyle(fontFamily: 'PublicSans'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AccountType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Account Type'),
                      items: AccountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase(), style: const TextStyle(fontFamily: 'PublicSans')),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(labelText: 'Initial Balance (₱)', hintText: '0.00'),
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

                    final accounts = ref.read(accountsListProvider).value ?? [];
                    final nameExists = accounts.any((a) => a.name.trim().toLowerCase() == name.toLowerCase());
                    if (nameExists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account name must be unique.')),
                      );
                      return;
                    }

                    final balanceDouble = double.tryParse(balanceController.text) ?? 0.0;
                    if (balanceDouble < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Initial balance cannot be negative.')),
                      );
                      return;
                    }

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