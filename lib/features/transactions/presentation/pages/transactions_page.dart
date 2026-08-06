import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/money_text.dart';
import '../providers/transaction_providers.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/category.dart';
import '../../../../shared/utils/category_icon_mapper.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _searchQuery = '';
  String? _filterAccountId;
  String? _filterCategoryId;
  String _filterType = 'all'; // 'all', 'income', 'expense', 'transfer'
  String _filterDateRange = 'all'; // 'all', 'today', 'week', 'month', 'custom'
  DateTimeRange? _customDateRange;

  bool get _hasAnyActiveFilter {
    return _filterAccountId != null ||
        _filterCategoryId != null ||
        _filterType != 'all' ||
        _filterDateRange != 'all';
  }

  void _resetFilters() {
    setState(() {
      _filterAccountId = null;
      _filterCategoryId = null;
      _filterType = 'all';
      _filterDateRange = 'all';
      _customDateRange = null;
    });
  }

  List<LedgerEntry> _getFilteredEntries(
    List<LedgerEntry> entries,
    List<Account> accounts,
    List<Category> categories,
  ) {
    return entries.where((entry) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final note = entry.note?.toLowerCase() ?? '';
        final amtText = (entry.amountMinor / 100).toStringAsFixed(2);
        
        final acc = accounts.firstWhere(
          (a) => a.id == entry.accountId,
          orElse: () => Account(
            id: '',
            name: '',
            accountType: AccountType.cash,
            openingBalanceMinor: 0,
            currency: '',
            icon: '',
            displayOrder: 0,
            isArchived: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.localOnly,
          ),
        );
        final accName = acc.name.toLowerCase();

        final cat = categories.firstWhere(
          (c) => c.id == entry.categoryId,
          orElse: () => Category(
            id: '',
            name: '',
            icon: '',
            color: '',
            categoryType: CategoryType.expense,
            isSystem: false,
            displayOrder: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.localOnly,
          ),
        );
        final catName = cat.name.toLowerCase();

        final matchesQuery = note.contains(_searchQuery.toLowerCase()) ||
            amtText.contains(_searchQuery) ||
            accName.contains(_searchQuery.toLowerCase()) ||
            catName.contains(_searchQuery.toLowerCase());
        if (!matchesQuery) return false;
      }

      // 2. Account Filter
      if (_filterAccountId != null && entry.accountId != _filterAccountId) {
        return false;
      }

      // 3. Category Filter
      if (_filterCategoryId != null && entry.categoryId != _filterCategoryId) {
        return false;
      }

      // 4. Type Filter
      if (_filterType != 'all') {
        if (_filterType == 'expense' && entry.direction != MoneyDirection.outflow) return false;
        if (_filterType == 'income' && entry.direction != MoneyDirection.inflow) return false;
        if (_filterType == 'transfer' && entry.transferId == null) return false;
      }

      // 5. Date Filter
      final date = entry.occurredAt.toLocal();
      final now = DateTime.now();
      if (_filterDateRange == 'today') {
        final todayStart = DateTime(now.year, now.month, now.day);
        if (date.isBefore(todayStart)) return false;
      } else if (_filterDateRange == 'week') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
        if (date.isBefore(weekStartDay)) return false;
      } else if (_filterDateRange == 'month') {
        final monthStart = DateTime(now.year, now.month, 1);
        if (date.isBefore(monthStart)) return false;
      } else if (_filterDateRange == 'custom' && _customDateRange != null) {
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  void _showTypeFilterSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Type', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                title: const Text('All Types', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterType == 'all' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterType = 'all');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Expense', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterType == 'expense' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterType = 'expense');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Income', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterType == 'income' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterType = 'income');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Transfer', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterType == 'transfer' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterType = 'transfer');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountFilterSelector(List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Account', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                title: const Text('All Accounts', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterAccountId == null ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterAccountId = null);
                  Navigator.pop(context);
                },
              ),
              ...accounts.map((acc) {
                return ListTile(
                  title: Text(acc.name, style: const TextStyle(fontFamily: 'PublicSans')),
                  trailing: _filterAccountId == acc.id ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                  onTap: () {
                    setState(() => _filterAccountId = acc.id);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryFilterSelector(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Category', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                title: const Text('All Categories', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterCategoryId == null ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterCategoryId = null);
                  Navigator.pop(context);
                },
              ),
              ...categories.map((cat) {
                return ListTile(
                  leading: Icon(mapCategoryIcon(cat.icon), color: AppTheme.carbonText.withOpacity(0.6)),
                  title: Text(cat.name, style: const TextStyle(fontFamily: 'PublicSans')),
                  trailing: _filterCategoryId == cat.id ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                  onTap: () {
                    setState(() => _filterCategoryId = cat.id);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showDateFilterSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Date Range', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                title: const Text('All Time', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterDateRange == 'all' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterDateRange = 'all');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Today', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterDateRange == 'today' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterDateRange = 'today');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('This Week', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterDateRange == 'week' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterDateRange = 'week');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('This Month', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterDateRange == 'month' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () {
                  setState(() => _filterDateRange = 'month');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Custom Range...', style: TextStyle(fontFamily: 'PublicSans')),
                trailing: _filterDateRange == 'custom' ? const Icon(Icons.check, color: AppTheme.oceanBlue) : null,
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDateRange: _customDateRange,
                  );
                  if (picked != null) {
                    setState(() {
                      _filterDateRange = 'custom';
                      _customDateRange = picked;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.oceanBlue.withOpacity(0.08) : AppTheme.carbonText.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.oceanBlue : AppTheme.carbonText.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppTheme.oceanBlue : AppTheme.carbonText.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? AppTheme.oceanBlue : AppTheme.carbonText.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledgerEntriesAsync = ref.watch(ledgerEntriesListProvider);
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    final accounts = accountsAsync.value ?? [];
    final allCategories = categoriesAsync.value ?? [];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add'),
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
      backgroundColor: AppTheme.paperBg,
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: AppTheme.paperBg,
        foregroundColor: AppTheme.carbonText,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.carbonText),
            onPressed: () => context.go('/add'),
          ),
        ],
      ),
      body: ledgerEntriesAsync.when(
        data: (entries) {
          final filtered = _getFilteredEntries(entries, accounts, allCategories);

          if (entries.isEmpty) {
            return EmptyState(
              message: "No ledger transactions recorded yet.",
              actionLabel: "Add Transaction",
              onAction: () => context.go('/add'),
            );
          }

          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppTheme.carbonText.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'PublicSans', fontSize: 14),
                ),
              ),
              // Horizontal filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Type Filter
                    _buildFilterChip(
                      label: _filterType == 'all' ? 'All Types' : _filterType.toUpperCase(),
                      isActive: _filterType != 'all',
                      onTap: () => _showTypeFilterSelector(),
                    ),
                    const SizedBox(width: 8),
                    // Account Filter
                    _buildFilterChip(
                      label: _filterAccountId == null 
                          ? 'All Accounts' 
                          : (accounts.firstWhere((a) => a.id == _filterAccountId, orElse: () => Account(id: '', name: 'Unknown', accountType: AccountType.cash, openingBalanceMinor: 0, currency: '', icon: '', displayOrder: 0, isArchived: false, createdAt: DateTime.now(), updatedAt: DateTime.now(), syncStatus: SyncStatus.localOnly)).name),
                      isActive: _filterAccountId != null,
                      onTap: () => _showAccountFilterSelector(accounts),
                    ),
                    const SizedBox(width: 8),
                    // Category Filter
                    _buildFilterChip(
                      label: _filterCategoryId == null 
                          ? 'All Categories' 
                          : (allCategories.firstWhere((c) => c.id == _filterCategoryId, orElse: () => Category(id: '', name: 'Unknown', icon: '', color: '', categoryType: CategoryType.expense, isSystem: false, displayOrder: 0, createdAt: DateTime.now(), updatedAt: DateTime.now(), syncStatus: SyncStatus.localOnly)).name),
                      isActive: _filterCategoryId != null,
                      onTap: () => _showCategoryFilterSelector(allCategories),
                    ),
                    const SizedBox(width: 8),
                    // Date Filter
                    _buildFilterChip(
                      label: _filterDateRange == 'all' 
                          ? 'All Time' 
                          : (_filterDateRange == 'custom' && _customDateRange != null
                              ? '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}' 
                              : _filterDateRange.toUpperCase()),
                      isActive: _filterDateRange != 'all',
                      onTap: () => _showDateFilterSelector(),
                    ),
                    if (_hasAnyActiveFilter) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.inkRed)),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // List view
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching transactions found.',
                          style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.carbonText.withOpacity(0.5)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => Divider(height: 1.0, color: AppTheme.carbonText.withOpacity(0.08)),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final isExpense = entry.direction == MoneyDirection.outflow;

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

                          final category = allCategories.firstWhere(
                            (c) => c.id == entry.categoryId,
                            orElse: () => Category(
                              id: '',
                              name: 'Unknown',
                              icon: '',
                              color: '',
                              categoryType: CategoryType.expense,
                              isSystem: false,
                              displayOrder: 0,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              syncStatus: SyncStatus.localOnly,
                            ),
                          );

                          return Dismissible(
                            key: Key(entry.id),
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
                                // Swipe start to end (left to right) -> Edit
                                context.go('/edit/${entry.id}');
                                return false; // Don't remove it from list
                              } else {
                                // Swipe end to start (right to left) -> Delete
                                bool deleteConfirmed = false;
                                await showDialog(
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
                                        onPressed: () {
                                          deleteConfirmed = true;
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inkRed),
                                        child: const Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (deleteConfirmed) {
                                  final entryToUndo = entry;
                                  await ref.read(transactionRepositoryProvider).deleteLedgerEntry(entry.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Transaction deleted.', style: TextStyle(fontFamily: 'PublicSans')),
                                        action: SnackBarAction(
                                          label: 'UNDO',
                                          onPressed: () async {
                                            await ref.read(transactionRepositoryProvider).updateLedgerEntry(
                                              entryToUndo.copyWith(deletedAt: null),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  return true;
                                }
                                return false;
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: (isExpense ? AppTheme.inkRed : AppTheme.registerGreen).withOpacity(0.1),
                                    child: Icon(
                                      isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                                      size: 16,
                                      color: isExpense ? AppTheme.inkRed : AppTheme.registerGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.note?.isNotEmpty == true ? entry.note! : (isExpense ? 'Expense' : 'Income'),
                                          style: const TextStyle(
                                            fontFamily: 'PublicSans',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppTheme.carbonText,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              account.name,
                                              style: TextStyle(
                                                fontFamily: 'PublicSans',
                                                fontSize: 11,
                                                color: AppTheme.carbonText.withOpacity(0.4),
                                              ),
                                            ),
                                            Text(
                                              ' • ${DateFormat('MMM d').format(entry.occurredAt.toLocal())}',
                                              style: TextStyle(
                                                fontFamily: 'PublicSans',
                                                fontSize: 11,
                                                color: AppTheme.carbonText.withOpacity(0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      MoneyText(
                                        amountMinor: entry.amountMinor,
                                        isNegative: isExpense,
                                        style: TextStyle(
                                          fontFamily: 'IBMPlexMono',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isExpense ? AppTheme.carbonText : AppTheme.oceanBlue,
                                        ),
                                      ),
                                      if (entry.categoryId != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.carbonText.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            category.name.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'PublicSans',
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.carbonText.withOpacity(0.5),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (err, stack) => ErrorState(errorMessage: err.toString()),
      ),
    );
  }
}
