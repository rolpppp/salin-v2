import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              'FINANCIAL TOOLS',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Manage Contacts', style: TextStyle(fontFamily: 'PublicSans')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.go('/contacts'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.event_repeat),
            title: const Text('Recurring Schedules', style: TextStyle(fontFamily: 'PublicSans')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.go('/recurring'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.handshake_outlined),
            title: const Text('Shared Splits & Loans', style: TextStyle(fontFamily: 'PublicSans')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.go('/splits_debts'),
          ),
          const Divider(height: 1),

          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              'SETTINGS',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title: const Text('Currency', style: TextStyle(fontFamily: 'PublicSans')),
            trailing: Text('PHP (₱)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Theme Accent', style: TextStyle(fontFamily: 'PublicSans')),
            trailing: Text('Ocean Blue', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: false,
            onChanged: (val) {},
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          const Divider(height: 1),

          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              'ABOUT',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Salin Personal Finance', style: TextStyle(fontFamily: 'PublicSans')),
            subtitle: Text('Version 1.0.0 (Local-First)', style: TextStyle(fontFamily: 'PublicSans')),
          ),
        ],
      ),
    );
  }
}
