import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../transactions/domain/entities/category.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(ledgerEntriesListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: entriesAsync.when(
        data: (entries) {
          final expenses = entries.where((e) => e.direction == MoneyDirection.outflow).toList();
          final income = entries.where((e) => e.direction == MoneyDirection.inflow).toList();

          if (entries.isEmpty) {
            return const EmptyState(
              message: 'Add transactions to view financial patterns.',
            );
          }

          final categories = categoriesAsync.value ?? [];

          // Group expenses by category
          final Map<String, int> expenseByCategory = {};
          int totalExpenses = 0;

          for (final exp in expenses) {
            final catId = exp.categoryId ?? 'unassigned';
            expenseByCategory[catId] = (expenseByCategory[catId] ?? 0) + exp.amountMinor;
            totalExpenses += exp.amountMinor;
          }

          int totalIncome = income.fold(0, (sum, item) => sum + item.amountMinor);

          // Convert grouped expenses to list and sort by spent amount descending
          final sortedCategoriesList = expenseByCategory.entries.map((entry) {
            final category = categories.firstWhere(
              (c) => c.id == entry.key,
              orElse: () => Category(
                id: entry.key,
                name: entry.key == 'unassigned' ? 'Unassigned' : 'Unknown',
                icon: 'category',
                color: '#808080',
                categoryType: CategoryType.expense,
                isSystem: false,
                displayOrder: 99,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                syncStatus: SyncStatus.localOnly,
              ),
            );
            return _CategorySpent(
              category: category,
              amountMinor: entry.value,
              percentage: totalExpenses > 0 ? entry.value / totalExpenses : 0.0,
            );
          }).toList()
            ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Summary Receipt
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'MONTHLY TOTALS',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Income', style: TextStyle(fontFamily: 'PublicSans', color: Colors.grey)),
                          MoneyText(
                            amountMinor: totalIncome,
                            style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Expenses', style: TextStyle(fontFamily: 'PublicSans', color: Colors.grey)),
                          MoneyText(
                            amountMinor: totalExpenses,
                            style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Balance', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
                          MoneyText(
                            amountMinor: (totalIncome - totalExpenses).abs(),
                            isNegative: (totalIncome - totalExpenses) < 0,
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: (totalIncome - totalExpenses) >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Breakdown Section
              if (sortedCategoriesList.isNotEmpty) ...[
                const SectionHeader(title: 'Expenses by Category'),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedCategoriesList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = sortedCategoriesList[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          child: const Icon(Icons.pie_chart_outline),
                        ),
                        title: Text(item.category.name, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: item.percentage,
                                minHeight: 4,
                                backgroundColor: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(item.percentage * 100).toStringAsFixed(1)}% of expenses',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: MoneyText(
                          amountMinor: item.amountMinor,
                          style: const TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _CategorySpent {
  final Category category;
  final int amountMinor;
  final double percentage;

  const _CategorySpent({
    required this.category,
    required this.amountMinor,
    required this.percentage,
  });
}
