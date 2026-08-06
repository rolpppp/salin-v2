import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/utils/category_icon_mapper.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/presentation/providers/contact_providers.dart';
import '../../../debts/domain/entities/debt.dart';
import '../../../debts/presentation/providers/debt_providers.dart';
import '../../../recurring/domain/entities/recurring_rule.dart';
import '../../../recurring/presentation/providers/recurring_providers.dart';
import '../../../splits/domain/entities/split.dart';
import '../../../splits/domain/entities/split_participant.dart';
import '../../../splits/presentation/providers/split_providers.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/transfer.dart';
import '../providers/transaction_providers.dart';
import '../widgets/quick_add_view.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final String? transactionId;

  const AddTransactionPage({super.key, this.transactionId});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _SplitRowData {
  String name = '';
  double share = 0.0;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController shareController = TextEditingController();

  void dispose() {
    nameController.dispose();
    shareController.dispose();
  }
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '0.00');
  final _noteController = TextEditingController();

  bool _showQuickAdd = false;

  MoneyDirection _selectedType = MoneyDirection.outflow;
  bool _isTransfer = false;

  bool _isSplit = false;
  bool _isDebt = false;
  bool _isRecurring = false;
  RecurringFrequency _recurringFrequency = RecurringFrequency.monthly;

  final List<_SplitRowData> _splitRows = [];

  final _debtContactController = TextEditingController();
  DateTime? _debtDueDate;

  String? _selectedSourceAccountId;
  String? _selectedDestAccountId;
  String? _selectedCategoryId;
  DateTime _occurredAt = DateTime.now();

  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final entry = await ref.read(transactionRepositoryProvider).getLedgerEntryById(widget.transactionId!);
        if (entry != null && mounted) {
          setState(() {
            _amountController.text = (entry.amountMinor / 100).toStringAsFixed(2);
            _noteController.text = entry.note ?? '';
            _selectedSourceAccountId = entry.accountId;
            _selectedCategoryId = entry.categoryId;
            _occurredAt = entry.occurredAt.toLocal();
            _selectedType = entry.direction;
            _isTransfer = entry.transferId != null;
            if (_isTransfer) {
              ref.read(transactionRepositoryProvider).getTransferById(entry.transferId!).then((t) {
                if (t != null && mounted) {
                  setState(() {
                    if (entry.direction == MoneyDirection.outflow) {
                      _selectedSourceAccountId = t.fromAccountId;
                      _selectedDestAccountId = t.toAccountId;
                    } else {
                      _selectedSourceAccountId = t.toAccountId;
                      _selectedDestAccountId = t.fromAccountId;
                    }
                  });
                }
              });
            }
          });
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDraft();
      });
    }
  }

  @override
  void dispose() {
    _handleDisposeDraft();
    _amountController.dispose();
    _noteController.dispose();
    _debtContactController.dispose();
    for (final row in _splitRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _handleDisposeDraft() async {
    if (!_isSubmitted) {
      await _saveDraft();
    } else {
      await _clearDraft();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: _occurredAt, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null && picked != _occurredAt) setState(() => _occurredAt = picked);
  }

  Future<void> _selectDebtDueDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: _debtDueDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
    if (picked != null) setState(() => _debtDueDate = picked);
  }

  Future<String> _findOrCreateContact(String name) async {
    final contacts = ref.read(contactsListProvider).value ?? [];
    Contact? existing;
    for (final c in contacts) {
      if (c.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        existing = c;
        break;
      }
    }
    if (existing != null) return existing.id;

    final contactId = "${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}";
    final newContact = Contact(
      id: contactId,
      name: name.trim(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      syncStatus: SyncStatus.localOnly,
    );
    await ref.read(contactRepositoryProvider).create(newContact);
    return contactId;
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amountDouble = double.tryParse(_amountController.text) ?? 0.0;
    final amountMinor = (amountDouble * 100).round();
    final note = _noteController.text.trim();

    if (_isTransfer) {
      if (_selectedSourceAccountId == null || _selectedDestAccountId == null) return;
      if (_selectedSourceAccountId == _selectedDestAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source and destination accounts must be different.')));
        return;
      }
      final transfer = Transfer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromAccountId: _selectedSourceAccountId!,
        toAccountId: _selectedDestAccountId!,
        note: note.isNotEmpty ? note : 'Transfer',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await ref.read(transactionRepositoryProvider).createTransfer(transfer, amountMinor: amountMinor, occurredAt: _occurredAt.toUtc());
    } else if (_isRecurring) {
      // Recurring takes priority over a one-off ledger entry: the rule
      // itself is the source of truth going forward, seeded with its first
      // upcoming instance rather than also writing a duplicate manual entry.
      if (_selectedSourceAccountId == null) return;
      if (_selectedType == MoneyDirection.outflow && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category for this expense.')));
        return;
      }
      final rule = RecurringRule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: note.isNotEmpty ? note : 'Recurring payment',
        accountId: _selectedSourceAccountId!,
        categoryId: _selectedCategoryId,
        amountMinor: amountMinor,
        direction: _selectedType,
        frequency: _recurringFrequency,
        interval: 1,
        startDate: _occurredAt.toUtc(),
        autoGenerate: true,
        note: note.isNotEmpty ? note : null,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await ref.read(recurringRepositoryProvider).createRule(rule);
      await ref.read(recurringRepositoryProvider).generateNextInstances(rule.id, 1);
    } else if (_isSplit) {
      if (_selectedSourceAccountId == null) return;
      final splitId = DateTime.now().millisecondsSinceEpoch.toString();
      final participants = <SplitParticipant>[];
      int totalSplitMinor = 0;

      for (final row in _splitRows) {
        final name = row.nameController.text.trim();
        final shareVal = double.tryParse(row.shareController.text.trim()) ?? 0.0;
        if (name.isEmpty || shareVal <= 0) continue;
        final contactId = await _findOrCreateContact(name);
        final shareMinor = (shareVal * 100).round();
        totalSplitMinor += shareMinor;
        participants.add(SplitParticipant(
          id: "${splitId}_$contactId",
          splitId: splitId,
          contactId: contactId,
          shareMinor: shareMinor,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ));
      }

      if (participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one participant with a share amount.')));
        return;
      }

      final splitObj = Split(
        id: splitId,
        title: note.isNotEmpty ? note : 'Split expense',
        totalMinor: totalSplitMinor,
        status: SplitStatus.active,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );

      await ref.read(splitRepositoryProvider).createSplit(
            splitObj,
            participants,
            accountId: _selectedSourceAccountId!,
            categoryId: _selectedCategoryId,
            occurredAt: _occurredAt.toUtc(),
          );
    } else if (_isDebt) {
      if (_selectedSourceAccountId == null) return;
      final friendName = _debtContactController.text.trim();
      if (friendName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend name is required for loan details.')));
        return;
      }
      final contactId = await _findOrCreateContact(friendName);
      final debtId = DateTime.now().millisecondsSinceEpoch.toString();
      final debtObj = Debt(
        id: debtId,
        contactId: contactId,
        isLent: _selectedType == MoneyDirection.outflow,
        principalMinor: amountMinor,
        dueDate: _debtDueDate?.toUtc(),
        status: DebtStatus.active,
        note: note.isNotEmpty ? note : (_selectedType == MoneyDirection.outflow ? 'Lent money' : 'Borrowed money'),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      await ref.read(debtRepositoryProvider).createDebt(debtObj, isLent: _selectedType == MoneyDirection.outflow, accountId: _selectedSourceAccountId!, occurredAt: _occurredAt.toUtc());
    } else {
      if (_selectedSourceAccountId == null) return;
      if (_selectedType == MoneyDirection.outflow && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category for this expense.')));
        return;
      }
      final entry = LedgerEntry(
        id: widget.transactionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        accountId: _selectedSourceAccountId!,
        categoryId: _selectedCategoryId,
        amountMinor: amountMinor,
        direction: _selectedType,
        origin: LedgerOrigin.manual,
        occurredAt: _occurredAt.toUtc(),
        note: note,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.localOnly,
      );
      if (widget.transactionId != null) {
        await ref.read(transactionRepositoryProvider).updateLedgerEntry(entry);
      } else {
        await ref.read(transactionRepositoryProvider).createLedgerEntry(entry);
      }
    }

    _isSubmitted = true;
    if (mounted) context.go('/transactions');
  }

  Future<void> _pickFromSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required IconData Function(T) iconOf,
    required void Function(T) onSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(title, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(iconOf(item), color: AppTheme.oceanBlue),
                    title: Text(labelOf(item), style: const TextStyle(fontFamily: 'PublicSans')),
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.carbonText.withOpacity(0.5)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontFamily: 'PublicSans', fontSize: 15))),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.carbonText.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _expandableRow({required IconData icon, required String label, required bool expanded, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.carbonText.withOpacity(0.6)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontFamily: 'PublicSans', fontSize: 15))),
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.carbonText.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.paperBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('New Entry'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.carbonText.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _segmentButton('Manual', !_showQuickAdd, () => setState(() => _showQuickAdd = false)),
                  _segmentButton('Quick Add', _showQuickAdd, () => setState(() => _showQuickAdd = true)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _showQuickAdd ? const QuickAddView() : _buildManualForm(context)),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? [BoxShadow(color: AppTheme.carbonText.withOpacity(0.08), blurRadius: 6)] : null,
        ),
        child: Text(label, style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, color: selected ? AppTheme.carbonText : AppTheme.carbonText.withOpacity(0.5))),
      ),
    );
  }

  Widget _buildManualForm(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    final accounts = (accountsAsync.value ?? []).where((a) => !a.isArchived).toList();
    final allCategories = categoriesAsync.value ?? [];

    final categoryType = _selectedType == MoneyDirection.inflow ? CategoryType.income : CategoryType.expense;
    final categories = allCategories.where((c) => c.categoryType == categoryType).toList();

    final selectedAccountName = accounts.where((a) => a.id == _selectedSourceAccountId).map((a) => a.name).firstOrNull ?? 'Select';
    final selectedCategoryName = categories.where((c) => c.id == _selectedCategoryId).map((c) => c.name).firstOrNull ?? 'Select';

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Direction toggle (kept from the original build; not shown in
            // the reference mock, which implicitly assumes expense, but
            // Income/Transfer still need a way in).
            Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                  ButtonSegment(value: 'transfer', label: Text('Transfer')),
                ],
                selected: {_isTransfer ? 'transfer' : (_selectedType == MoneyDirection.outflow ? 'expense' : 'income')},
                onSelectionChanged: (selection) {
                  setState(() {
                    final selected = selection.first;
                    if (selected == 'transfer') {
                      _isTransfer = true;
                      _isSplit = false;
                      _isDebt = false;
                      _isRecurring = false;
                    } else {
                      _isTransfer = false;
                      _selectedType = selected == 'expense' ? MoneyDirection.outflow : MoneyDirection.inflow;
                      _selectedCategoryId = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Big centered amount display
            Center(
              child: Column(
                children: [
                  IntrinsicWidth(
                    child: TextFormField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 40, fontWeight: FontWeight.w700, color: AppTheme.carbonText),
                      decoration: const InputDecoration(border: InputBorder.none, prefixText: '₱  ', prefixStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 32, color: AppTheme.carbonText)),
                      validator: (val) {
                        final parsed = double.tryParse(val ?? '');
                        if (parsed == null || parsed <= 0) return 'Amount must be greater than zero.';
                        return null;
                      },
                    ),
                  ),
                  Text('AMOUNT', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, letterSpacing: 1.2, color: AppTheme.carbonText.withOpacity(0.4))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description (moved up from the bottom of the form, per the
            // reference design — same _noteController underneath)
            const Text('DESCRIPTION', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'What was this for?', border: UnderlineInputBorder()),
              style: const TextStyle(fontFamily: 'PublicSans', fontSize: 15),
            ),
            const SizedBox(height: 20),

            // Category / Account row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isTransfer)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CATEGORY', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                        _pickerRow(
                          icon: Icons.category_outlined,
                          label: selectedCategoryName,
                          onTap: () => _pickFromSheet<dynamic>(
                            context: context,
                            title: 'Select Category',
                            items: categories,
                            labelOf: (c) => c.name as String,
                            iconOf: (c) => mapCategoryIcon(c.icon as String),
                            onSelected: (c) => setState(() => _selectedCategoryId = c.id as String),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isTransfer ? 'FROM ACCOUNT' : 'ACCOUNT', style: const TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                      _pickerRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: selectedAccountName,
                        onTap: () => _pickFromSheet<dynamic>(
                          context: context,
                          title: 'Select Account',
                          items: accounts,
                          labelOf: (a) => a.name as String,
                          iconOf: (_) => Icons.account_balance_wallet_outlined,
                          onSelected: (a) => setState(() => _selectedSourceAccountId = a.id as String),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isTransfer) ...[
              const SizedBox(height: 20),
              const Text('TO ACCOUNT', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
              _pickerRow(
                icon: Icons.account_balance_wallet_outlined,
                label: accounts.where((a) => a.id == _selectedDestAccountId).map((a) => a.name).firstOrNull ?? 'Select',
                onTap: () => _pickFromSheet<dynamic>(
                  context: context,
                  title: 'Select Destination Account',
                  items: accounts,
                  labelOf: (a) => a.name as String,
                  iconOf: (_) => Icons.account_balance_wallet_outlined,
                  onSelected: (a) => setState(() => _selectedDestAccountId = a.id as String),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text('DATE', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.carbonText.withOpacity(0.15)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_occurredAt.month.toString().padLeft(2, '0')}/${_occurredAt.day.toString().padLeft(2, '0')}/${_occurredAt.year}',
                        style: const TextStyle(fontFamily: 'PublicSans', fontSize: 15)),
                    Icon(Icons.calendar_today, size: 18, color: AppTheme.carbonText.withOpacity(0.5)),
                  ],
                ),
              ),
            ),

            if (!_isTransfer) ...[
              const Divider(height: 32),
              _expandableRow(
                icon: Icons.group_add_outlined,
                label: 'Split with others',
                expanded: _isSplit,
                onTap: () => setState(() {
                  _isSplit = !_isSplit;
                  if (_isSplit) {
                    _isDebt = false;
                    _isRecurring = false;
                    if (_splitRows.isEmpty) _splitRows.add(_SplitRowData());
                  }
                }),
              ),
              if (_isSplit) _buildSplitRows(),

              const Divider(height: 1),
              _expandableRow(
                icon: Icons.handshake_outlined,
                label: 'This is a debt',
                expanded: _isDebt,
                onTap: () => setState(() {
                  _isDebt = !_isDebt;
                  if (_isDebt) {
                    _isSplit = false;
                    _isRecurring = false;
                  }
                }),
              ),
              if (_isDebt) _buildDebtFields(context),

              const Divider(height: 1),
              _expandableRow(
                icon: Icons.autorenew,
                label: 'Make this recurring',
                expanded: _isRecurring,
                onTap: () => setState(() {
                  _isRecurring = !_isRecurring;
                  if (_isRecurring) {
                    _isSplit = false;
                    _isDebt = false;
                  }
                }),
              ),
              if (_isRecurring) _buildRecurringFields(),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.carbonText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('ADD TRANSACTION', style: TextStyle(fontFamily: 'PublicSans', fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitRows() {
    final contacts = ref.watch(contactsListProvider).value ?? [];
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SHARED SPLIT PARTICIPANTS', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _splitRows.length,
            itemBuilder: (context, idx) {
              final row = _splitRows[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Autocomplete<String>(
                        optionsBuilder: (val) => val.text.isEmpty ? const Iterable<String>.empty() : contacts.map((c) => c.name).where((n) => n.toLowerCase().contains(val.text.toLowerCase())),
                        onSelected: (sel) => row.nameController.text = sel,
                        fieldViewBuilder: (ctx, textCtrl, node, onSub) {
                          if (textCtrl.text != row.nameController.text) textCtrl.text = row.nameController.text;
                          textCtrl.addListener(() => row.nameController.text = textCtrl.text);
                          return TextFormField(controller: textCtrl, focusNode: node, decoration: const InputDecoration(labelText: 'Name', hintText: 'Friend name'), style: const TextStyle(fontFamily: 'PublicSans'));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(controller: row.shareController, decoration: const InputDecoration(labelText: 'Share', hintText: '0.00', prefixText: '₱ '), keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontFamily: 'IBMPlexMono')),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.inkRed),
                      onPressed: () => setState(() {
                        row.dispose();
                        _splitRows.removeAt(idx);
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
          TextButton.icon(
            onPressed: () => setState(() => _splitRows.add(_SplitRowData())),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Friend', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtFields(BuildContext context) {
    final contacts = ref.watch(contactsListProvider).value ?? [];
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_selectedType == MoneyDirection.outflow ? 'LENDING DETAILS' : 'BORROWING DETAILS', style: const TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Autocomplete<String>(
            optionsBuilder: (val) => val.text.isEmpty ? const Iterable<String>.empty() : contacts.map((c) => c.name).where((n) => n.toLowerCase().contains(val.text.toLowerCase())),
            onSelected: (sel) => _debtContactController.text = sel,
            fieldViewBuilder: (ctx, textCtrl, node, onSub) {
              if (textCtrl.text != _debtContactController.text) textCtrl.text = _debtContactController.text;
              textCtrl.addListener(() => _debtContactController.text = textCtrl.text);
              return TextFormField(controller: textCtrl, focusNode: node, decoration: const InputDecoration(labelText: 'Friend Name *', hintText: 'Who lent or borrowed?'), style: const TextStyle(fontFamily: 'PublicSans'));
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due Date (Optional)', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(_debtDueDate != null ? _debtDueDate!.toLocal().toString().substring(0, 10) : 'None', style: const TextStyle(fontFamily: 'IBMPlexMono')),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDebtDueDate(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringFields() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('RECURRING FREQUENCY', style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          DropdownButtonFormField<RecurringFrequency>(
            initialValue: _recurringFrequency,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: RecurringFrequency.weekly, child: Text('Weekly', style: TextStyle(fontFamily: 'PublicSans'))),
              DropdownMenuItem(value: RecurringFrequency.monthly, child: Text('Monthly', style: TextStyle(fontFamily: 'PublicSans'))),
              DropdownMenuItem(value: RecurringFrequency.quarterly, child: Text('Quarterly', style: TextStyle(fontFamily: 'PublicSans'))),
              DropdownMenuItem(value: RecurringFrequency.yearly, child: Text('Yearly', style: TextStyle(fontFamily: 'PublicSans'))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _recurringFrequency = val);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (widget.transactionId != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final amt = _amountController.text;
    final note = _noteController.text;
    
    if ((amt.isEmpty || amt == '0.00') && note.isEmpty) {
      await _clearDraft();
      return;
    }
    
    await prefs.setString('draft_amount', amt);
    await prefs.setString('draft_note', note);
    await prefs.setInt('draft_type', _selectedType.index);
    await prefs.setBool('draft_is_transfer', _isTransfer);
    if (_selectedSourceAccountId != null) {
      await prefs.setString('draft_source_account_id', _selectedSourceAccountId!);
    } else {
      await prefs.remove('draft_source_account_id');
    }
    if (_selectedDestAccountId != null) {
      await prefs.setString('draft_dest_account_id', _selectedDestAccountId!);
    } else {
      await prefs.remove('draft_dest_account_id');
    }
    if (_selectedCategoryId != null) {
      await prefs.setString('draft_category_id', _selectedCategoryId!);
    } else {
      await prefs.remove('draft_category_id');
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_amount');
    await prefs.remove('draft_note');
    await prefs.remove('draft_type');
    await prefs.remove('draft_is_transfer');
    await prefs.remove('draft_source_account_id');
    await prefs.remove('draft_dest_account_id');
    await prefs.remove('draft_category_id');
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final amt = prefs.getString('draft_amount');
    final note = prefs.getString('draft_note');
    if ((amt == null || amt == '0.00') && (note == null || note.isEmpty)) return;
    
    if (!mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Draft', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: const Text('You have an unsaved transaction draft. Would you like to restore it?', style: TextStyle(fontFamily: 'PublicSans')),
        actions: [
          TextButton(
            onPressed: () {
              _clearDraft();
              Navigator.pop(context, false);
            },
            child: const Text('Discard', style: TextStyle(fontFamily: 'PublicSans', color: AppTheme.inkRed)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      setState(() {
        _amountController.text = amt ?? '0.00';
        _noteController.text = note ?? '';
        _selectedType = MoneyDirection.values[prefs.getInt('draft_type') ?? 1];
        _isTransfer = prefs.getBool('draft_is_transfer') ?? false;
        _selectedSourceAccountId = prefs.getString('draft_source_account_id');
        _selectedDestAccountId = prefs.getString('draft_dest_account_id');
        _selectedCategoryId = prefs.getString('draft_category_id');
      });
    }
  }
}