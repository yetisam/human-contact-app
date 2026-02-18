import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../widgets/hc_card.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification settings (stored locally for now)
  bool _connectionRequests = true;
  bool _newMessages = true;
  bool _exchangeUpdates = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).user;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(HCSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),

              // Settings content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Section
                      _buildSectionTitle('Account'),
                      HCCard(
                        child: Column(
                          children: [
                            _buildSettingsItem(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              subtitle: 'Update your account password',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildInfoItem(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              value: user?.email ?? 'Not available',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: HCSpacing.lg),

                      // Notifications Section
                      _buildSectionTitle('Notifications'),
                      HCCard(
                        child: Column(
                          children: [
                            _buildSwitchItem(
                              icon: Icons.person_add_outlined,
                              title: 'Connection requests',
                              subtitle: 'Get notified when someone wants to connect',
                              value: _connectionRequests,
                              onChanged: (value) => setState(() => _connectionRequests = value),
                            ),
                            const Divider(height: 1),
                            _buildSwitchItem(
                              icon: Icons.message_outlined,
                              title: 'New messages',
                              subtitle: 'Get notified about new chat messages',
                              value: _newMessages,
                              onChanged: (value) => setState(() => _newMessages = value),
                            ),
                            const Divider(height: 1),
                            _buildSwitchItem(
                              icon: Icons.swap_horiz,
                              title: 'Exchange updates',
                              subtitle: 'Get notified about contact exchanges',
                              value: _exchangeUpdates,
                              onChanged: (value) => setState(() => _exchangeUpdates = value),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: HCSpacing.lg),

                      // Privacy Section
                      _buildSectionTitle('Privacy'),
                      HCCard(
                        child: Column(
                          children: [
                            _buildSettingsItem(
                              icon: Icons.block_outlined,
                              title: 'Block list',
                              subtitle: 'Manage blocked users',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildSettingsItem(
                              icon: Icons.download_outlined,
                              title: 'Data export',
                              subtitle: 'Download your data',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: HCSpacing.lg),

                      // Danger Zone Section
                      _buildSectionTitle('Danger Zone', color: HCColors.error),
                      HCCard(
                        child: _buildSettingsItem(
                          icon: Icons.delete_forever_outlined,
                          title: 'Delete Account',
                          subtitle: 'Permanently delete your account and all data',
                          titleColor: HCColors.error,
                          iconColor: HCColors.error,
                          onTap: _showDeleteAccountDialog,
                        ),
                      ),

                      // Bottom spacing
                      const SizedBox(height: HCSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HCSpacing.sm, top: HCSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color ?? HCColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(HCSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? HCColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? HCColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: HCSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: titleColor ?? HCColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HCColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: HCColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(HCSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HCColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: HCColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: HCSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HCColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(HCSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HCColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: HCColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: HCSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HCColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: HCColors.primary,
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HCColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HCRadius.md),
        ),
        title: Text(
          'Delete Account?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: HCColors.error,
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data including connections, messages, and profile information will be permanently deleted.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: HCColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact support to delete your account'),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: HCColors.error),
            ),
          ),
        ],
      ),
    );
  }
}