import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/database_provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/sync/sync_service.dart';
import '../../../../core/services/sync/sync_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_provider.dart';
import '../../../../core/config/ai_config.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'PublicSans',
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAccentCircle(BuildContext context, WidgetRef ref, SettingRow settings, String themeKey, Color color) {
    final isSelected = settings.accentTheme == themeKey;
    return GestureDetector(
      onTap: () {
        ref.read(settingsRepositoryProvider).updateSettings(
          settings.copyWith(accentTheme: themeKey),
        );
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, SettingRow settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('PHP (₱)', style: TextStyle(fontFamily: 'PublicSans')),
              onTap: () async {
                await ref.read(settingsRepositoryProvider).updateSettings(settings.copyWith(currency: 'PHP'));
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWeekStartDialog(BuildContext context, WidgetRef ref, SettingRow settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Week starts on', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Monday', style: TextStyle(fontFamily: 'PublicSans')),
              onTap: () async {
                await ref.read(settingsRepositoryProvider).updateSettings(settings.copyWith(weekStart: 1));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sunday', style: TextStyle(fontFamily: 'PublicSans')),
              onTap: () async {
                await ref.read(settingsRepositoryProvider).updateSettings(settings.copyWith(weekStart: 7));
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                const SizedBox(height: 8),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 1. APPEARANCE
                _buildSectionTitle(context, 'APPEARANCE'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Midnight mode',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Reduce glare in low light',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            Checkbox(
                              value: settings.themeMode == 1,
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(settingsRepositoryProvider).updateSettings(
                                    settings.copyWith(themeMode: val ? 1 : 0),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Accent theme',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  settings.accentTheme.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildAccentCircle(context, ref, settings, 'ocean', const Color(0xFF2E6EA6)),
                                const SizedBox(width: 12),
                                _buildAccentCircle(context, ref, settings, 'forest', const Color(0xFF2E4C38)),
                                const SizedBox(width: 12),
                                _buildAccentCircle(context, ref, settings, 'terracotta', const Color(0xFFC75A3E)),
                                const SizedBox(width: 12),
                                _buildAccentCircle(context, ref, settings, 'purple', const Color(0xFF7D6FAB)),
                                const SizedBox(width: 12),
                                _buildAccentCircle(context, ref, settings, 'rose', const Color(0xFFD6949F)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. FINANCIAL TOOLS
                _buildSectionTitle(context, 'FINANCIAL TOOLS'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.people_outline, color: Theme.of(context).colorScheme.onSurface),
                        title: const Text('Manage Contacts', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () => context.go('/contacts'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.category_outlined, color: Theme.of(context).colorScheme.onSurface),
                        title: const Text('Manage Categories', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () => context.go('/categories'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.event_repeat, color: Theme.of(context).colorScheme.onSurface),
                        title: const Text('Recurring Schedules', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () => context.go('/recurring'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.handshake_outlined, color: Theme.of(context).colorScheme.onSurface),
                        title: const Text('Shared Splits & Loans', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () => context.go('/splits_debts'),
                      ),
                    ],
                  ),
                ),

                // 3. PREFERENCES
                _buildSectionTitle(context, 'PREFERENCES'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Currency', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.currency,
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _showCurrencyDialog(context, ref, settings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Week starts on', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.weekStart == 7 ? 'Sunday' : 'Monday',
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _showWeekStartDialog(context, ref, settings),
                      ),
                    ],
                  ),
                ),

                // 4. SECURITY
                _buildSectionTitle(context, 'SECURITY'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Biometric lock',
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: settings.biometricLock,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(settingsRepositoryProvider).updateSettings(
                                settings.copyWith(biometricLock: val),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 4b. AI & PRIVACY
                _buildSectionTitle(context, 'AI & PRIVACY'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final cloudAiEnabled = ref.watch(cloudAiEnabledProvider);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_sync_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text(
                                      'Use Cloud AI for Quick Add',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Text(
                                      "Falls back to Google Gemini for messy input Salin can't parse on-device. Off by default — your entries stay on this device unless you turn this on.",
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: cloudAiEnabled,
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(cloudAiEnabledProvider.notifier).setEnabled(val);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 5. CLOUD SYNCHRONIZATION
                _buildSectionTitle(context, 'CLOUD SYNCHRONIZATION'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final auth = ref.watch(authProvider);
                      final isAuthed = auth.status == AuthStatus.authenticated;

                      return Column(
                        children: [
                          if (!isAuthed) ...[
                            ListTile(
                              leading: Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.onSurface),
                              title: const Text('Enable Cloud Sync', style: TextStyle(fontFamily: 'PublicSans')),
                              subtitle: const Text('Sign in to sync your data', style: TextStyle(fontFamily: 'PublicSans', fontSize: 12)),
                              trailing: TextButton(
                                onPressed: () => context.push('/login'),
                                child: Text('SIGN IN', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                              ),
                            ),
                          ] else ...[
                            ListTile(
                              leading: Icon(Icons.cloud_queue, color: Theme.of(context).colorScheme.primary),
                              title: const Text('Connected Account', style: TextStyle(fontFamily: 'PublicSans')),
                              subtitle: Text(auth.email ?? '', style: const TextStyle(fontFamily: 'PublicSans', fontSize: 12)),
                              trailing: TextButton(
                                onPressed: () => ref.read(authProvider.notifier).logout(),
                                child: const Text('LOG OUT', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold, color: AppTheme.inkRed)),
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.sync, color: Theme.of(context).colorScheme.onSurface, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Auto Cloud Sync',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: settings.syncEnabled,
                                    activeColor: Theme.of(context).colorScheme.primary,
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(settingsRepositoryProvider).updateSettings(
                                          settings.copyWith(syncEnabled: val),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Consumer(
                              builder: (context, ref, child) {
                                final syncState = ref.watch(syncProvider);
                                String syncSubtitle = 'Never synced';
                                if (syncState.isSyncing) {
                                  syncSubtitle = 'Syncing...';
                                } else if (syncState.error != null) {
                                  syncSubtitle = 'Error: ${syncState.error}';
                                } else if (syncState.lastSyncTime != null) {
                                  syncSubtitle = 'Last synced: ${_formatDateTime(syncState.lastSyncTime)}';
                                }

                                return ListTile(
                                  leading: Icon(Icons.sync, color: Theme.of(context).colorScheme.onSurface),
                                  title: const Text('Synchronize Now', style: TextStyle(fontFamily: 'PublicSans')),
                                  subtitle: Text(syncSubtitle, style: const TextStyle(fontFamily: 'PublicSans', fontSize: 12)),
                                  trailing: syncState.isSyncing
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                                        )
                                      : const Icon(Icons.sync, color: Colors.grey, size: 18),
                                  onTap: syncState.isSyncing
                                      ? null
                                      : () async {
                                          final done = await ref.read(syncProvider.notifier).runSync();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(done ? 'Sync completed successfully!' : 'Sync failed.')),
                                            );
                                          }
                                        },
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.onSurface),
                              title: const Text('Upload Cloud Backup', style: TextStyle(fontFamily: 'PublicSans')),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                              onTap: () => _cloudBackup(context, ref),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.cloud_download_outlined, color: Theme.of(context).colorScheme.onSurface),
                              title: const Text('Restore from Cloud', style: TextStyle(fontFamily: 'PublicSans')),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                              onTap: () => _cloudRestore(context, ref),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 6. BACKUP & SYSTEM
                _buildSectionTitle(context, 'BACKUP & SYSTEM'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.backup_outlined, color: Theme.of(context).colorScheme.onSurface),
                        title: const Text('Export Backup', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () => _exportBackup(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.settings_backup_restore, color: Theme.of(context).colorScheme.onSurface),
                        title: const Text('Restore Backup', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () => _restoreBackup(context, ref),
                      ),
                    ],
                  ),
                ),

                // 6. SUPPORT
                _buildSectionTitle(context, 'SUPPORT'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Help Center', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help Center is under development.')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Contact Support', style: TextStyle(fontFamily: 'PublicSans')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support email: support@salin.app')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'Salin Version 1.0.4 (Build 492)',
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const LoadingState(),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing database backup...')),
    );
    final success = await ref.read(backupServiceProvider).exportBackup();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup export cancelled or failed.')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: const Text(
          'WARNING: Restoring a backup file will overwrite all current local data. This action is irreversible. Are you sure you want to proceed?',
          style: TextStyle(fontFamily: 'PublicSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inkRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Close db first so files are not locked
    await ref.read(databaseProvider).close();

    final success = await ref.read(backupServiceProvider).restoreBackup();

    if (context.mounted) {
      if (success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
            content: const Text(
              'Database has been restored successfully. The application will now close. Please reopen Salin to load your restored data.',
              style: TextStyle(fontFamily: 'PublicSans'),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => exit(0),
                child: const Text('Exit App', style: TextStyle(fontFamily: 'PublicSans')),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore backup. Current database remains active.')),
        );
      }
    }
  }

  Future<void> _cloudBackup(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading database backup to cloud...')),
    );
    final success = await ref.read(syncProvider.notifier).runCloudBackup();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup upload failed.')),
        );
      }
    }
  }

  Future<void> _cloudRestore(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cloud Restore', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
        content: const Text(
          'WARNING: Restoring from cloud will overwrite all current local data. This action is irreversible. Are you sure you want to proceed?',
          style: TextStyle(fontFamily: 'PublicSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'PublicSans')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inkRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(fontFamily: 'PublicSans', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref.read(syncProvider.notifier).runCloudRestore();

    if (context.mounted) {
      if (success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
            content: const Text(
              'Database has been restored from the cloud successfully. The application will now close. Please reopen Salin to load your restored data.',
              style: TextStyle(fontFamily: 'PublicSans'),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => exit(0),
                child: const Text('Exit App', style: TextStyle(fontFamily: 'PublicSans')),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download or restore cloud backup. Current database remains active.')),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Never';
    return DateFormat('MMM d, yyyy HH:mm').format(dt.toLocal());
  }
}
