import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/presentation/providers/contact_providers.dart';
import '../../../debts/domain/entities/debt.dart';
import '../../../debts/presentation/providers/debt_providers.dart';
import '../../../splits/domain/entities/split.dart';
import '../../../splits/domain/entities/split_participant.dart';
import '../../../splits/presentation/providers/split_providers.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/transfer.dart';
import '../providers/transaction_providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

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
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  MoneyDirection _selectedType = MoneyDirection.outflow;
  bool _isTransfer = false;

  // Split/Loan Flags
  bool _isSplit = false;
  bool _isDebt = false;

  // Split Form Fields
  final List<_SplitRowData> _splitRows = [];

  // Debt Form Fields
  final _debtContactController = TextEditingController();
  DateTime? _debtDueDate;

  String? _selectedSourceAccountId;
  String? _selectedDestAccountId;
  String? _selectedCategoryId;
  DateTime _occurredAt = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _debtContactController.dispose();
    for (final row in _splitRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _occurredAt) {
      setState(() {
        _occurredAt = picked;
      });
    }
  }

  Future<void> _selectDebtDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _debtDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _debtDueDate = picked;
      });
    }
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

    if (existing != null) {
      return existing.id;
    }

    // Create new contact dynamically
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts must be different.')),
        );
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

      await ref.read(transactionRepositoryProvider).createTransfer(
            transfer,
            amountMinor: amountMinor,
            occurredAt: _occurredAt.toUtc(),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one participant with a share amount.')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend name is required for loan details.')),
        );
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

      await ref.read(debtRepositoryProvider).createDebt(
            debtObj,
            isLent: _selectedType == MoneyDirection.outflow,
            accountId: _selectedSourceAccountId!,
            occurredAt: _occurredAt.toUtc(),
          );
    } else {
      if (_selectedSourceAccountId == null) return;
      if (_selectedType == MoneyDirection.outflow && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category for this expense.')),
        );
        return;
      }

      final entry = LedgerEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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

      await ref.read(transactionRepositoryProvider).createLedgerEntry(entry);
    }

    if (mounted) {
      context.go('/transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final contactsAsync = ref.watch(contactsListProvider);

    final accounts = accountsAsync.value ?? [];
    final allCategories = categoriesAsync.value ?? [];
    final contacts = contactsAsync.value ?? [];

    final categoryType = _selectedType == MoneyDirection.inflow ? CategoryType.income : CategoryType.expense;
    final categories = allCategories.where((c) => c.categoryType == categoryType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented controls
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_outward)),
                  ButtonSegment<String>(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment<String>(value: 'transfer', label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
                ],
                selected: <String>{
                  _isTransfer ? 'transfer' : (_selectedType == MoneyDirection.outflow ? 'expense' : 'income')
                },
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    final selected = newSelection.first;
                    if (selected == 'transfer') {
                      _isTransfer = true;
                      _isSplit = false;
                      _isDebt = false;
                    } else {
                      _isTransfer = false;
                      _selectedType = selected == 'expense' ? MoneyDirection.outflow : MoneyDirection.inflow;
                      _selectedCategoryId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // Amount Input
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₱)',
                  hintText: '0.00',
                  prefixText: '₱ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 24, fontWeight: FontWeight.bold),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an amount.';
                  }
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedSourceAccountId,
                decoration: InputDecoration(
                  labelText: _isTransfer ? 'From Account' : 'Account',
                ),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text(acc.name, style: const TextStyle(fontFamily: 'PublicSans')),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSourceAccountId = val;
                  });
                },
                validator: (val) => val == null ? 'Please select an account.' : null,
              ),
              const SizedBox(height: 16),

              // Account Selector (Destination - Transfer only)
              if (_isTransfer) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedDestAccountId,
                  decoration: const InputDecoration(
                    labelText: 'To Account',
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text(acc.name, style: const TextStyle(fontFamily: 'PublicSans')),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDestAccountId = val;
                    });
                  },
                  validator: (val) => val == null ? 'Please select a destination account.' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Category Selector (Non-transfers only)
              if (!_isTransfer) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name, style: const TextStyle(fontFamily: 'PublicSans')),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  },
                  validator: (val) {
                    if (_selectedType == MoneyDirection.outflow && val == null && !_isSplit && !_isDebt) {
                      return 'Category is required for expenses.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Toggles for Shared Split / Loan (Non-transfers only)
              if (!_isTransfer) ...[
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isSplit,
                        title: const Text('Shared Split', style: TextStyle(fontFamily: 'PublicSans', fontSize: 14)),
                        onChanged: (val) {
                          setState(() {
                            _isSplit = val ?? false;
                            if (_isSplit) {
                              _isDebt = false;
                              if (_splitRows.isEmpty) {
                                _splitRows.add(_SplitRowData());
                              }
                            }
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isDebt,
                        title: const Text('Personal Loan', style: TextStyle(fontFamily: 'PublicSans', fontSize: 14)),
                        onChanged: (val) {
                          setState(() {
                            _isDebt = val ?? false;
                            if (_isDebt) {
                              _isSplit = false;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Expanded Shared Split form
              if (_isSplit && !_isTransfer) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'SHARED SPLIT PARTICIPANTS',
                        style: TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                      ),
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
                                    optionsBuilder: (TextEditingValue textVal) {
                                      if (textVal.text.isEmpty) return const Iterable<String>.empty();
                                      return contacts
                                          .map((c) => c.name)
                                          .where((n) => n.toLowerCase().contains(textVal.text.toLowerCase()));
                                    },
                                    onSelected: (String sel) {
                                      row.nameController.text = sel;
                                    },
                                    fieldViewBuilder: (ctx, textCtrl, node, onSub) {
                                      // Link our Row controller to Autocomplete controller
                                      if (textCtrl.text != row.nameController.text) {
                                        textCtrl.text = row.nameController.text;
                                      }
                                      textCtrl.addListener(() {
                                        row.nameController.text = textCtrl.text;
                                      });
                                      return TextFormField(
                                        controller: textCtrl,
                                        focusNode: node,
                                        decoration: const InputDecoration(labelText: 'Name', hintText: 'Friend name'),
                                        style: const TextStyle(fontFamily: 'PublicSans'),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: row.shareController,
                                    decoration: const InputDecoration(labelText: 'Share', hintText: '0.00', prefixText: '₱ '),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontFamily: 'IBMPlexMono'),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      row.dispose();
                                      _splitRows.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _splitRows.add(_SplitRowData());
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Friend', style: TextStyle(fontFamily: 'PublicSans')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Expanded Loan / Debt form
              if (_isDebt && !_isTransfer) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _selectedType == MoneyDirection.outflow ? 'LENDING DETAILS' : 'BORROWING DETAILS',
                        style: const TextStyle(fontFamily: 'PublicSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textVal) {
                          if (textVal.text.isEmpty) return const Iterable<String>.empty();
                          return contacts
                              .map((c) => c.name)
                              .where((n) => n.toLowerCase().contains(textVal.text.toLowerCase()));
                        },
                        onSelected: (String sel) {
                          _debtContactController.text = sel;
                        },
                        fieldViewBuilder: (ctx, textCtrl, node, onSub) {
                          if (textCtrl.text != _debtContactController.text) {
                            textCtrl.text = _debtContactController.text;
                          }
                          textCtrl.addListener(() {
                            _debtContactController.text = textCtrl.text;
                          });
                          return TextFormField(
                            controller: textCtrl,
                            focusNode: node,
                            decoration: const InputDecoration(labelText: 'Friend Name *', hintText: 'Who lent or borrowed?'),
                            style: const TextStyle(fontFamily: 'PublicSans'),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date (Optional)', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          _debtDueDate != null ? _debtDueDate!.toLocal().toString().substring(0, 10) : 'None',
                          style: const TextStyle(fontFamily: 'IBMPlexMono'),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDebtDueDate(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Date Picker Field
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _occurredAt.toLocal().toString().substring(0, 16),
                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 16),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Note Field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Add description...',
                ),
                style: const TextStyle(fontFamily: 'PublicSans'),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Record Transaction',
                  style: TextStyle(fontFamily: 'PublicSans', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
