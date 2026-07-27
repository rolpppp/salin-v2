import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/utils/category_icon_mapper.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../transactions/domain/entities/category.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCategoryDialog(context, ref),
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add, size: 28),
        ),
        appBar: AppBar(
          title: const Text('Manage Categories'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Category',
              onPressed: () => _showAddCategoryDialog(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: categoriesAsync.when(
          data: (categories) {
            final expenses = categories.where((c) => c.categoryType == CategoryType.expense).toList();
            final incomes = categories.where((c) => c.categoryType == CategoryType.income).toList();

            return TabBarView(
              children: [
                _buildCategoryList(context, ref, expenses, CategoryType.expense),
                _buildCategoryList(context, ref, incomes, CategoryType.income),
              ],
            );
          },
          loading: () => const LoadingState(),
          error: (err, stack) => ErrorState(errorMessage: err.toString()),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, WidgetRef ref, List<Category> categories, CategoryType type) {
    if (categories.isEmpty) {
      return EmptyState(
        message: 'No categories created for this type yet.',
        actionLabel: 'Add Category',
        onAction: () => _showAddCategoryDialog(context, ref, initialType: type),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final cat = categories[index];
        Color catColor;
        try {
          catColor = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
        } catch (_) {
          catColor = AppTheme.oceanBlue;
        }

        final item = ListTile(
          leading: CircleAvatar(
            backgroundColor: catColor.withOpacity(0.12),
            child: Icon(
              mapCategoryIcon(cat.icon),
              color: catColor,
              size: 20,
            ),
          ),
          title: Text(
            cat.name,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            cat.isSystem ? 'System Category (Locked)' : 'Custom Category',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12,
              color: cat.isSystem ? AppTheme.carbonText.withOpacity(0.4) : AppTheme.oceanBlue.withOpacity(0.6),
            ),
          ),
          trailing: cat.isSystem
              ? Icon(Icons.lock_outline, color: AppTheme.carbonText.withOpacity(0.3), size: 16)
              : null,
        );

        if (cat.isSystem) {
          return item;
        }

        return Dismissible(
          key: Key(cat.id),
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
              _showEditCategoryDialog(context, ref, cat);
              return false;
            } else {
              bool deleteConfirmed = false;
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Category', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to delete this category? Historical transactions will be set to Unassigned.', style: TextStyle(fontFamily: 'PublicSans')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inkRed),
                      onPressed: () {
                        deleteConfirmed = true;
                        Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (deleteConfirmed) {
                await ref.read(transactionRepositoryProvider).deleteCategory(cat.id);
                return true;
              }
              return false;
            }
          },
          child: item,
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the category "${category.name}"? Historical transaction records will keep this category details, but you will not be able to choose it for new entries.', style: const TextStyle(fontFamily: 'PublicSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(transactionRepositoryProvider).deleteCategory(category.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inkRed),
            child: const Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref, {CategoryType? initialType}) {
    _showCategoryForm(context, ref, initialType: initialType);
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category) {
    _showCategoryForm(context, ref, categoryToEdit: category);
  }

  void _showCategoryForm(BuildContext context, WidgetRef ref, {CategoryType? initialType, Category? categoryToEdit}) {
    final isEditing = categoryToEdit != null;
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    CategoryType selectedType = categoryToEdit?.categoryType ?? initialType ?? CategoryType.expense;
    String selectedIcon = categoryToEdit?.icon ?? 'category';
    String selectedColor = categoryToEdit?.color ?? '#2E6EA6';

    final presetColors = [
      '#2E6EA6', // Ocean Blue
      '#3F7D58', // Emerald Green
      '#C98A3D', // Warm Amber
      '#A83232', // Ink Red
      '#3A3A3A', // Charcoal
      '#6B5B95', // Deep Violet
      '#FF6F61', // Sweet Rose
      '#008080', // Teal
    ];

    final presetIcons = [
      'category',
      'food',
      'coffee',
      'transport',
      'home',
      'utilities',
      'shopping',
      'entertainment',
      'health',
      'salary',
    ];

    final Map<String, IconData> iconNameMapping = {
      'category': Icons.category_outlined,
      'food': Icons.restaurant_outlined,
      'coffee': Icons.coffee_outlined,
      'transport': Icons.directions_car_outlined,
      'home': Icons.home_outlined,
      'utilities': Icons.bolt_outlined,
      'shopping': Icons.shopping_bag_outlined,
      'entertainment': Icons.movie_outlined,
      'health': Icons.favorite_border,
      'salary': Icons.payments_outlined,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Category' : 'Add Category', style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Category Name *'),
                      style: const TextStyle(fontFamily: 'PublicSans'),
                    ),
                    const SizedBox(height: 16),
                    if (!isEditing) ...[
                      DropdownButtonFormField<CategoryType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(labelText: 'Category Type'),
                        items: const [
                          DropdownMenuItem(value: CategoryType.expense, child: Text('EXPENSE', style: TextStyle(fontFamily: 'PublicSans'))),
                          DropdownMenuItem(value: CategoryType.income, child: Text('INCOME', style: TextStyle(fontFamily: 'PublicSans'))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text('Select Icon', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetIcons.map((iconKey) {
                        final isSelected = selectedIcon == iconKey;
                        return InkWell(
                          onTap: () => setState(() => selectedIcon = iconKey),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.oceanBlue.withOpacity(0.12) : Colors.transparent,
                              border: Border.all(color: isSelected ? AppTheme.oceanBlue : Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              iconNameMapping[iconKey] ?? Icons.category_outlined,
                              color: isSelected ? AppTheme.oceanBlue : AppTheme.carbonText.withOpacity(0.7),
                              size: 18,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Color', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetColors.map((colorHex) {
                        final isSelected = selectedColor == colorHex;
                        final colorVal = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                        return InkWell(
                          onTap: () => setState(() => selectedColor = colorHex),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorVal,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
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

                    final allCats = ref.read(categoriesListProvider).value ?? [];
                    final nameExists = allCats.any((c) =>
                        c.id != categoryToEdit?.id &&
                        c.categoryType == selectedType &&
                        c.name.trim().toLowerCase() == name.toLowerCase());

                    if (nameExists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category name must be unique within this type.')),
                      );
                      return;
                    }

                    if (isEditing) {
                      final updated = categoryToEdit.copyWith(
                        name: name,
                        icon: selectedIcon,
                        color: selectedColor,
                        updatedAt: DateTime.now().toUtc(),
                        syncStatus: SyncStatus.localOnly,
                      );
                      await ref.read(transactionRepositoryProvider).updateCategory(updated);
                    } else {
                      final newCat = Category(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        icon: selectedIcon,
                        color: selectedColor,
                        categoryType: selectedType,
                        isSystem: false,
                        displayOrder: DateTime.now().millisecondsSinceEpoch,
                        createdAt: DateTime.now().toUtc(),
                        updatedAt: DateTime.now().toUtc(),
                        syncStatus: SyncStatus.localOnly,
                      );
                      await ref.read(transactionRepositoryProvider).createCategory(newCat);
                    }

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
