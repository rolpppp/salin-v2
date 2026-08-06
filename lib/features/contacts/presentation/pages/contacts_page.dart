import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../providers/contact_providers.dart';
import '../../domain/entities/contact.dart';

class ContactsPage extends ConsumerWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context, ref),
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactDialog(context, ref),
          ),
        ],
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return EmptyState(
              message: 'No contacts added yet.',
              actionLabel: 'Add Contact',
              onAction: () => _showAddContactDialog(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: contacts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    contact.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                title: Text(contact.name, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w600)),
                subtitle: Text(
                  contact.phone ?? contact.email ?? 'No contact details',
                  style: const TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor, size: 20),
                      onPressed: () => _showEditContactDialog(context, ref, contact),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(context, ref, contact),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, WidgetRef ref, Contact contact) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone ?? '');
    final emailController = TextEditingController(text: contact.email ?? '');
    final notesController = TextEditingController(text: contact.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                style: const TextStyle(fontFamily: 'PublicSans'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontFamily: 'PublicSans'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontFamily: 'PublicSans'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                style: const TextStyle(fontFamily: 'PublicSans'),
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

              final updated = contact.copyWith(
                name: name,
                phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                updatedAt: DateTime.now().toUtc(),
                syncStatus: SyncStatus.localOnly,
              );

              await ref.read(contactRepositoryProvider).update(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${contact.name}? Historical transactions remain unaffected.', style: const TextStyle(fontFamily: 'PublicSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(contactRepositoryProvider).delete(contact.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                style: const TextStyle(fontFamily: 'PublicSans'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontFamily: 'PublicSans'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontFamily: 'PublicSans'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                style: const TextStyle(fontFamily: 'PublicSans'),
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

              final contact = Contact(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
                syncStatus: SyncStatus.localOnly,
              );

              await ref.read(contactRepositoryProvider).create(contact);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }
}
