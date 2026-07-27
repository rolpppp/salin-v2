import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/presentation/providers/contact_providers.dart';
import '../../../debts/presentation/providers/debt_providers.dart';
import '../../../recurring/domain/entities/recurring_rule.dart';
import '../../../recurring/presentation/providers/recurring_providers.dart';
import '../../../splits/presentation/providers/split_providers.dart';
import '../../../transactions/domain/entities/ledger_entry.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good morning.";
    } else if (hour >= 12 && hour < 18) {
      return "Good afternoon.";
    } else {
      return "Good evening.";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEntriesAsync = ref.watch(ledgerEntriesListProvider);
    final activeBudgetAsync = ref.watch(activeBudgetProvider);
    final activeBudget = activeBudgetAsync.value;
    final accountsAsync = ref.watch(accountsListProvider);
    final upcomingInstancesAsync = ref.watch(upcomingInstancesListProvider);
    final recurringRulesAsync = ref.watch(recurringRulesListProvider);
    final contacts = ref.watch(contactsListProvider).value ?? [];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add'),
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/salin-logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
            const SizedBox(width: 8),
            const Text(
              'Salin',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contextual Greeting and Insight
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                if (activeBudget != null)
                  ref.watch(budgetSummaryProvider(activeBudget.id)).when(
                        data: (summary) {
                          // Find top category spent
                          final sortedCategories = List<CategoryBudgetSummary>.from(summary.categorySummaries)
                            ..sort((a, b) => b.spentMinor.compareTo(a.spentMinor));
                          final topCategory = sortedCategories.isEmpty ? null : sortedCategories.first;

                          if (topCategory != null && topCategory.spentMinor > 0) {
                            final pct = (topCategory.progress * 100).toStringAsFixed(0);
                            return Text(
                              "You've spent $pct% of your ${topCategory.categoryName.toLowerCase()} budget.",
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          } else {
                            return const Text(
                              "Your budget is set up and ready.",
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          }
                        },
                        loading: () => const SizedBox(),
                        error: (e, s) => const SizedBox(),
                      )
                else
                  const Text(
                    "Set up a monthly budget to track your spending capacity.",
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Hero: Total Balance Card
            ref.watch(totalBalanceProvider).when(
              data: (totalBalance) {
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Accent Line
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'TOTAL BALANCE',
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            MoneyText(
                              amountMinor: totalBalance,
                              style: const TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Combined balance across all active accounts',
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.inkRed.withOpacity(0.2)),
                ),
                child: const Text(
                  'Error calculating total balance',
                  style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.inkRed),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAccountCategoriesBar(
              context,
              ref,
              accountsAsync.value ?? [],
              recentEntriesAsync.value ?? [],
            ),
            const SizedBox(height: 20),
            _buildBudgetSummaryCard(context, ref, activeBudget),
            const SizedBox(height: 24),

            // Bento Grid: Upcoming & Owed to You
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool isWide = width > 500;

                Widget bentoBody() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Upcoming Obligations Widget
                      _BentoCard(
                        title: "UPCOMING",
                        icon: Icons.event,
                        child: upcomingInstancesAsync.when(
                          data: (instances) {
                            final pending = instances.where((i) => i.status == RecurringInstanceStatus.pending).take(2).toList();
                            if (pending.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No upcoming obligations', style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: AppTheme.carbonText.withOpacity(0.5))),
                              );
                            }
                            final rules = recurringRulesAsync.value ?? [];
                            return Column(
                              children: List.generate(pending.length, (idx) {
                                final inst = pending[idx];
                                final rule = rules.firstWhere((r) => r.id == inst.recurringRuleId, orElse: () => _dummyRule(inst.recurringRuleId));
                                final isLast = idx == pending.length - 1;
                                return Column(
                                  children: [
                                    _BentoListRow(title: rule.title, valueMinor: rule.amountMinor, isPositive: false),
                                    if (!isLast) const Divider(height: 12),
                                  ],
                                );
                              }),
                            );
                          },
                          loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                          error: (e, s) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Owed to You Widget
                      _BentoCard(
                        title: "OWED TO YOU",
                        icon: Icons.payments,
                        child: _OwedToYouBentoList(contacts: contacts),
                      ),
                    ],
                  );
                }

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BentoCard(
                          title: "UPCOMING",
                          icon: Icons.event,
                          child: upcomingInstancesAsync.when(
                            data: (instances) {
                              final pending = instances.where((i) => i.status == RecurringInstanceStatus.pending).take(2).toList();
                              if (pending.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('No upcoming obligations', style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: AppTheme.carbonText.withOpacity(0.5))),
                                );
                              }
                              final rules = recurringRulesAsync.value ?? [];
                              return Column(
                                children: List.generate(pending.length, (idx) {
                                  final inst = pending[idx];
                                  final rule = rules.firstWhere((r) => r.id == inst.recurringRuleId, orElse: () => _dummyRule(inst.recurringRuleId));
                                  final isLast = idx == pending.length - 1;
                                  return Column(
                                    children: [
                                      _BentoListRow(title: rule.title, valueMinor: rule.amountMinor, isPositive: false),
                                      if (!isLast) const Divider(height: 12),
                                    ],
                                  );
                                }),
                              );
                            },
                            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                            error: (e, s) => const SizedBox(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BentoCard(
                          title: "OWED TO YOU",
                          icon: Icons.payments,
                          child: _OwedToYouBentoList(contacts: contacts),
                        ),
                      ),
                    ],
                  );
                }

                return bentoBody();
              },
            ),
            const SizedBox(height: 24),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT ACTIVITY',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    letterSpacing: 1.5,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('View All', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            recentEntriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyState(
                    message: "No transactions recorded yet.",
                  );
                }
                final recent = entries.take(3).toList();
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recent.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = recent[index];
                      final isExpense = entry.direction == MoneyDirection.outflow;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isExpense ? AppTheme.inkRed : AppTheme.registerGreen).withOpacity(0.1),
                          child: Icon(
                            isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                            color: isExpense ? AppTheme.inkRed : AppTheme.registerGreen,
                          ),
                        ),
                        title: Text(
                          entry.note != null && entry.note!.isNotEmpty
                              ? entry.note!
                              : (isExpense ? 'Expense' : 'Income'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'PublicSans'),
                        ),
                        subtitle: Text(
                          entry.occurredAt.toLocal().toString().substring(0, 16),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        trailing: MoneyText(
                          amountMinor: entry.amountMinor,
                          isNegative: isExpense,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'IBMPlexMono',
                            color: isExpense ? AppTheme.inkRed : AppTheme.registerGreen,
                          ),
                        ),
                      );
                    },
                  ),
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

  Widget _buildAccountCategoriesBar(BuildContext context, WidgetRef ref, List<Account> accounts, List<LedgerEntry> entries) {
    if (accounts.isEmpty) return const SizedBox();

    final Map<AccountType, int> categoryBalances = {};

    for (final acc in accounts) {
      categoryBalances[acc.accountType] = (categoryBalances[acc.accountType] ?? 0) + acc.openingBalanceMinor;
    }

    for (final entry in entries) {
      Account? acc;
      for (final a in accounts) {
        if (a.id == entry.accountId) {
          acc = a;
          break;
        }
      }
      if (acc == null) continue;

      final direction = entry.direction;
      if (direction == MoneyDirection.inflow) {
        categoryBalances[acc.accountType] = (categoryBalances[acc.accountType] ?? 0) + entry.amountMinor;
      } else {
        categoryBalances[acc.accountType] = (categoryBalances[acc.accountType] ?? 0) - entry.amountMinor;
      }
    }

    final activeTypes = AccountType.values.where((t) => accounts.any((a) => a.accountType == t)).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: activeTypes.map((type) {
          final balance = categoryBalances[type] ?? 0;
          final icon = _getAccountCategoryIcon(type);
          final name = _getAccountCategoryName(type);

          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '-',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 6),
                MoneyText(
                  amountMinor: balance,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? AppTheme.registerGreen : AppTheme.inkRed,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetSummaryCard(BuildContext context, WidgetRef ref, Budget? activeBudget) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    if (activeBudget == null) {
      return InkWell(
        onTap: () => context.go('/budgets'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACTIVE BUDGET',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor.withOpacity(0.6),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: onSurfaceColor.withOpacity(0.4)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Set up a monthly budget to track your spending capacity.',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 14,
                  color: onSurfaceColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'SET UP BUDGET',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(budgetSummaryProvider(activeBudget.id));

    return summaryAsync.when(
      data: (summary) {
        final progress = summary.totalLimitMinor > 0 ? (summary.totalSpentMinor / summary.totalLimitMinor) : 0.0;
        final isOverspent = summary.totalSpentMinor > summary.totalLimitMinor;

        Color getProgressColor(double progress, bool isOver) {
          if (isOver) return AppTheme.inkRed;
          if (progress > 0.8) return AppTheme.warningAmber;
          return AppTheme.registerGreen;
        }

        final progressColor = getProgressColor(progress, isOverspent);

        return InkWell(
          onTap: () => context.go('/budgets'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE BUDGET',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor.withOpacity(0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          activeBudget.name,
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: onSurfaceColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18, color: onSurfaceColor.withOpacity(0.4)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          MoneyText(
                            amountMinor: summary.remainingMinor.abs(),
                            muteDecimals: true,
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isOverspent ? AppTheme.inkRed : AppTheme.oceanBlue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOverspent ? 'overspent' : 'remaining',
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13,
                              color: onSurfaceColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% spent',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: onSurfaceColor.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Spent: ',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 12,
                            color: onSurfaceColor.withOpacity(0.5),
                          ),
                        ),
                        MoneyText(
                          amountMinor: summary.totalSpentMinor,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onSurfaceColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Limit: ',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 12,
                            color: onSurfaceColor.withOpacity(0.5),
                          ),
                        ),
                        MoneyText(
                          amountMinor: summary.totalLimitMinor,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onSurfaceColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.inkRed.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text('Error loading budget summary', style: TextStyle(color: AppTheme.inkRed)),
        ),
      ),
    );
  }

  IconData _getAccountCategoryIcon(AccountType type) {
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
        return Icons.credit_card_outlined;
      case AccountType.investment:
        return Icons.trending_up_outlined;
    }
  }

  String _getAccountCategoryName(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank';
      case AccountType.savings:
        return 'Savings';
      case AccountType.eWallet:
        return 'e-Wallet';
      case AccountType.creditCard:
        return 'Credit';
      case AccountType.debitCard:
        return 'Debit';
      case AccountType.investment:
        return 'Investment';
    }
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
}

class _BentoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _BentoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BentoListRow extends StatelessWidget {
  final String title;
  final int valueMinor;
  final bool isPositive;

  const _BentoListRow({
    required this.title,
    required this.valueMinor,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontFamily: 'PublicSans', fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        MoneyText(
          amountMinor: valueMinor,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isPositive ? AppTheme.registerGreen : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _OwedToYouBentoList extends ConsumerWidget {
  final List<Contact> contacts;

  const _OwedToYouBentoList({required this.contacts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(activeDebtsListProvider);
    final splitsAsync = ref.watch(activeSplitsListProvider);

    return debtsAsync.when(
      data: (debts) {
        return splitsAsync.when(
          data: (splits) {
            final lentDebts = debts.where((d) => d.isLent).toList();
            final List<Widget> items = [];

            for (final debt in lentDebts) {
              final balanceAsync = ref.watch(debtRemainingBalanceProvider(debt.id));
              final balance = balanceAsync.value ?? debt.principalMinor;
              if (balance <= 0) continue;

              Contact? contact;
              for (final c in contacts) {
                if (c.id == debt.contactId) {
                  contact = c;
                  break;
                }
              }
              final name = contact?.name ?? 'Someone';

              items.add(
                _BentoListRow(
                  title: "$name (Loan)",
                  valueMinor: balance,
                  isPositive: true,
                ),
              );
            }

            for (final split in splits) {
              final balanceAsync = ref.watch(splitRemainingBalanceProvider(split.id));
              final balance = balanceAsync.value ?? split.totalMinor;
              if (balance <= 0) continue;

              items.add(
                _BentoListRow(
                  title: split.title,
                  valueMinor: balance,
                  isPositive: true,
                ),
              );
            }

            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No outstanding balances',
                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: AppTheme.carbonText.withOpacity(0.5)),
                ),
              );
            }

            final display = items.take(2).toList();
            return Column(
              children: List.generate(display.length, (idx) {
                final isLast = idx == display.length - 1;
                return Column(
                  children: [
                    display[idx],
                    if (!isLast) const Divider(height: 12),
                  ],
                );
              }),
            );
          },
          loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
      error: (e, s) => const SizedBox(),
    );
  }
}
