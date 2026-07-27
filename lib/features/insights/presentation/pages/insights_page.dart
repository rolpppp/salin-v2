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

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  DateTime? _selectedMonth;
  bool _showAllCategories = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(ledgerEntriesListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      body: SafeArea(
        child: entriesAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const EmptyState(
                message: 'Add transactions to view financial patterns.',
              );
            }

            // Get unique months from entries
            final List<DateTime> uniqueMonths = [];
            for (final entry in entries) {
              final date = entry.occurredAt.toLocal();
              final monthStart = DateTime(date.year, date.month, 1);
              if (!uniqueMonths.any((m) => m.year == monthStart.year && m.month == monthStart.month)) {
                uniqueMonths.add(monthStart);
              }
            }
            uniqueMonths.sort((a, b) => b.compareTo(a)); // Descending

            // Set default month
            final activeMonth = _selectedMonth ?? uniqueMonths.first;
            if (!uniqueMonths.any((m) => m.year == activeMonth.year && m.month == activeMonth.month)) {
              // Reset if selected month is no longer in list
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedMonth = uniqueMonths.first;
                });
              });
            }

            final precedingMonth = DateTime(activeMonth.year, activeMonth.month - 1, 1);

            // Filter entries for active month and preceding month
            final activeEntries = entries.where((e) {
              final date = e.occurredAt.toLocal();
              return date.year == activeMonth.year && date.month == activeMonth.month;
            }).toList();

            final prevEntries = entries.where((e) {
              final date = e.occurredAt.toLocal();
              return date.year == precedingMonth.year && date.month == precedingMonth.month;
            }).toList();

            // Active month totals
            final activeExpenses = activeEntries.where((e) => e.direction == MoneyDirection.outflow).toList();
            final activeIncome = activeEntries.where((e) => e.direction == MoneyDirection.inflow).toList();
            final int activeTotalExpenses = activeExpenses.fold(0, (sum, item) => sum + item.amountMinor);
            final int activeTotalIncome = activeIncome.fold(0, (sum, item) => sum + item.amountMinor);

            // Preceding month totals
            final prevExpenses = prevEntries.where((e) => e.direction == MoneyDirection.outflow).toList();
            final int prevTotalExpenses = prevExpenses.fold(0, (sum, item) => sum + item.amountMinor);

            // Calculations for comparison (Scenario Detection)
            final oldestDate = entries.map((e) => e.occurredAt.toLocal()).reduce((a, b) => a.isBefore(b) ? a : b);
            final startTrackingMonth = DateTime(oldestDate.year, oldestDate.month, 1);
            final isFirstMonth = activeMonth.year == startTrackingMonth.year && activeMonth.month == startTrackingMonth.month;

            Widget card1;

            if (isFirstMonth) {
              card1 = _buildObservationCard(
                context: context,
                icon: Icons.stars_outlined,
                iconColor: AppTheme.oceanBlue,
                badgeLabel: 'TRACKING',
                badgeBgColor: AppTheme.oceanBlue.withOpacity(0.08),
                badgeTextColor: AppTheme.oceanBlue,
                mainText: 'This is your first month of tracking.',
                subText: "You've recorded ${activeEntries.length} entries so far in ${DateFormat('MMMM').format(activeMonth)}.",
              );
            } else if (activeExpenses.isEmpty) {
              // Find the most recent active spending month before activeMonth
              int mostRecentPrevSpending = 0;
              DateTime? mostRecentPrevMonth;
              for (final m in uniqueMonths) {
                if (m.isBefore(activeMonth)) {
                  final monthEntries = entries.where((e) {
                    final date = e.occurredAt.toLocal();
                    return date.year == m.year && date.month == m.month;
                  }).toList();
                  final monthExpenses = monthEntries
                      .where((e) => e.direction == MoneyDirection.outflow)
                      .fold(0, (sum, item) => sum + item.amountMinor);
                  if (monthExpenses > 0) {
                    mostRecentPrevSpending = monthExpenses;
                    mostRecentPrevMonth = m;
                    break;
                  }
                }
              }

              card1 = _buildObservationCard(
                context: context,
                icon: Icons.calendar_today_outlined,
                iconColor: onSurfaceColor.withOpacity(0.6),
                badgeLabel: 'OBSERVATION',
                badgeBgColor: onSurfaceColor.withOpacity(0.06),
                badgeTextColor: onSurfaceColor.withOpacity(0.6),
                mainText: 'No spending recorded this month yet.',
                subText: mostRecentPrevMonth != null
                    ? 'In ${DateFormat('MMMM').format(mostRecentPrevMonth)}, you spent ₱${(mostRecentPrevSpending / 100).toStringAsFixed(2)}.'
                    : 'No prior spending recorded.',
              );
            } else {
              // Active month has spending, and it's not the first month.
              // Find most recent active spending month before activeMonth to compare with if immediate preceding month is empty
              int comparisonSpending = prevTotalExpenses;
              String comparisonLabel = 'last month';

              if (prevTotalExpenses == 0) {
                int mostRecentPrevSpending = 0;
                DateTime? mostRecentPrevMonth;
                for (final m in uniqueMonths) {
                  if (m.isBefore(activeMonth)) {
                    final monthEntries = entries.where((e) {
                      final date = e.occurredAt.toLocal();
                      return date.year == m.year && date.month == m.month;
                    }).toList();
                    final monthExpenses = monthEntries
                        .where((e) => e.direction == MoneyDirection.outflow)
                        .fold(0, (sum, item) => sum + item.amountMinor);
                    if (monthExpenses > 0) {
                      mostRecentPrevSpending = monthExpenses;
                      mostRecentPrevMonth = m;
                      break;
                    }
                  }
                }
                if (mostRecentPrevSpending > 0 && mostRecentPrevMonth != null) {
                  comparisonSpending = mostRecentPrevSpending;
                  comparisonLabel = 'in ${DateFormat('MMMM').format(mostRecentPrevMonth)}';
                }
              }

              if (comparisonSpending > 0) {
                final int diff = activeTotalExpenses - comparisonSpending;
                final double percentage = (diff / comparisonSpending * 100).abs();

                card1 = _buildObservationCard(
                  context: context,
                  icon: diff <= 0 ? Icons.trending_down : Icons.trending_up,
                  iconColor: diff <= 0 ? AppTheme.oceanBlue : AppTheme.inkRed,
                  badgeLabel: diff <= 0 ? 'POSITIVE' : 'OBSERVATION',
                  badgeBgColor: diff <= 0
                      ? AppTheme.oceanBlue.withOpacity(0.08)
                      : onSurfaceColor.withOpacity(0.06),
                  badgeTextColor: diff <= 0
                      ? AppTheme.oceanBlue
                      : onSurfaceColor.withOpacity(0.6),
                  mainText: diff <= 0
                      ? 'You spent ${percentage.toStringAsFixed(0)}% less than $comparisonLabel.'
                      : 'You spent ${percentage.toStringAsFixed(0)}% more than $comparisonLabel.',
                  subText: '${diff <= 0 ? '-' : '+'}₱${(diff.abs() / 100).toStringAsFixed(2)}',
                );
              } else {
                // If there's truly no prior spending at all
                card1 = _buildObservationCard(
                  context: context,
                  icon: Icons.trending_flat,
                  iconColor: onSurfaceColor.withOpacity(0.6),
                  badgeLabel: 'OBSERVATION',
                  badgeBgColor: onSurfaceColor.withOpacity(0.06),
                  badgeTextColor: onSurfaceColor.withOpacity(0.6),
                  mainText: 'Spent ₱${(activeTotalExpenses / 100).toStringAsFixed(2)} this month.',
                  subText: 'No prior spending history to compare.',
                );
              }
            }

            // Group expenses by category
            final categories = categoriesAsync.value ?? [];
            final Map<String, int> expenseByCategory = {};
            for (final exp in activeExpenses) {
              final catId = exp.categoryId ?? 'unassigned';
              expenseByCategory[catId] = (expenseByCategory[catId] ?? 0) + exp.amountMinor;
            }

            // Sort categories by spent descending
            final sortedCategoriesList = expenseByCategory.entries.map((entry) {
              final category = categories.firstWhere(
                (c) => c.id == entry.key,
                orElse: () => Category(
                  id: entry.key,
                  name: entry.key == 'unassigned' ? 'Unassigned' : 'Unknown',
                  icon: entry.key == 'unassigned' ? 'other' : 'category',
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
                percentage: activeTotalExpenses > 0 ? entry.value / activeTotalExpenses : 0.0,
              );
            }).toList()
              ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

            // Weekly spending trends in the active month
            // Week 1: 1-7, Week 2: 8-14, Week 3: 15-21, Week 4+: 22+
            int w1 = 0, w2 = 0, w3 = 0, w4 = 0;
            for (final exp in activeExpenses) {
              final day = exp.occurredAt.toLocal().day;
              if (day <= 7) {
                w1 += exp.amountMinor;
              } else if (day <= 14) {
                w2 += exp.amountMinor;
              } else if (day <= 21) {
                w3 += exp.amountMinor;
              } else {
                w4 += exp.amountMinor;
              }
            }
            final weeklyTotals = [w1, w2, w3, w4];
            final maxWeekly = weeklyTotals.reduce((a, b) => a > b ? a : b);

            final monthAbbr = DateFormat('MMM').format(activeMonth);
            final lastDay = DateTime(activeMonth.year, activeMonth.month + 1, 0).day;
            final weekLabels = [
              '$monthAbbr 1-7',
              '$monthAbbr 8-14',
              '$monthAbbr 15-21',
              '$monthAbbr 22-$lastDay',
            ];

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              children: [
                const SizedBox(height: 8),

                // Title: Insights
                Text(
                  'Insights',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),

                // Selected Month Picker Button
                GestureDetector(
                  onTap: () => _showMonthPicker(context, uniqueMonths),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(activeMonth),
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: onSurfaceColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: onSurfaceColor.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Card 1: Spending Trend Observation (Positive/Caution)
                card1,
                const SizedBox(height: 16),

                // Card 2: Largest Expense Category Observation
                if (sortedCategoriesList.isNotEmpty) ...[
                  _buildObservationCard(
                    context: context,
                    icon: mapCategoryIcon(sortedCategoriesList.first.category.icon),
                    iconColor: onSurfaceColor.withOpacity(0.6),
                    badgeLabel: 'OBSERVATION',
                    badgeBgColor: onSurfaceColor.withOpacity(0.06),
                    badgeTextColor: onSurfaceColor.withOpacity(0.6),
                    mainText: '${sortedCategoriesList.first.category.name} remains your largest expense.',
                    subText: '${(sortedCategoriesList.first.percentage * 100).toStringAsFixed(0)}% of total',
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  _buildObservationCard(
                    context: context,
                    icon: Icons.info_outline,
                    iconColor: onSurfaceColor.withOpacity(0.6),
                    badgeLabel: 'OBSERVATION',
                    badgeBgColor: onSurfaceColor.withOpacity(0.06),
                    badgeTextColor: onSurfaceColor.withOpacity(0.6),
                    mainText: 'No expenses recorded for this month.',
                    subText: '0% of total',
                  ),
                  const SizedBox(height: 32),
                ],

                // Spending Trend Section Header
                Text(
                  'SPENDING TREND',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: onSurfaceColor.withOpacity(0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Spending Trend Card
                Card(
                  elevation: 0,
                  color: Theme.of(context).cardTheme.color,
                  shape: Theme.of(context).cardTheme.shape,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < weeklyTotals.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 85,
                                  child: Text(
                                    weekLabels[i],
                                    style: TextStyle(
                                      fontFamily: 'PublicSans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: onSurfaceColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: maxWeekly > 0 ? weeklyTotals[i] / maxWeekly : 0.0,
                                      minHeight: 6,
                                      backgroundColor: onSurfaceColor.withOpacity(0.06),
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.oceanBlue),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 75,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: MoneyText(
                                      amountMinor: weeklyTotals[i],
                                      style: TextStyle(
                                        fontFamily: 'IBMPlexMono',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Categories Section Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CATEGORIES',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: onSurfaceColor.withOpacity(0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (sortedCategoriesList.length > 3)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllCategories = !_showAllCategories;
                          });
                        },
                        child: Text(
                          _showAllCategories ? 'Show Less' : 'View All',
                          style: const TextStyle(
                            fontFamily: 'PublicSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.oceanBlue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Categories Flat List with dividers
                if (sortedCategoriesList.isNotEmpty) ...[
                  Divider(height: 1, color: onSurfaceColor.withOpacity(0.08)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _showAllCategories
                        ? sortedCategoriesList.length
                        : (sortedCategoriesList.length > 3 ? 3 : sortedCategoriesList.length),
                    separatorBuilder: (context, index) => Divider(height: 1, color: onSurfaceColor.withOpacity(0.08)),
                    itemBuilder: (context, index) {
                      final item = sortedCategoriesList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: onSurfaceColor.withOpacity(0.06),
                              radius: 18,
                              child: Icon(
                                mapCategoryIcon(item.category.icon),
                                color: onSurfaceColor.withOpacity(0.6),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.category.name,
                                style: TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: onSurfaceColor,
                                ),
                              ),
                            ),
                            MoneyText(
                              amountMinor: item.amountMinor,
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: onSurfaceColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: onSurfaceColor.withOpacity(0.08)),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No category activity this month.',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 14,
                          color: onSurfaceColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const LoadingState(),
          error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: onSurfaceColor))),
        ),
      ),
    );
  }

  Widget _buildObservationCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String badgeLabel,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String mainText,
    required String subText,
  }) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardTheme.color,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mainText,
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onSurfaceColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subText,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: onSurfaceColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, List<DateTime> months) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Month',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final m = months[index];
                    final isSelected = m.year == (_selectedMonth?.year ?? months.first.year) &&
                        m.month == (_selectedMonth?.month ?? months.first.month);
                    return ListTile(
                      title: Text(
                        DateFormat('MMMM yyyy').format(m),
                        style: const TextStyle(fontFamily: 'PublicSans'),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                      onTap: () {
                        setState(() {
                          _selectedMonth = m;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
