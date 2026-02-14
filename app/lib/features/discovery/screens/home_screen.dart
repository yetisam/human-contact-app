import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/hc_card.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(HCSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hey ${user?.firstName ?? 'there'} 👋',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready to make a real connection?',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // Logout button (temp)
                    IconButton(
                      icon: const Icon(Icons.logout, color: HCColors.textMuted),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go(Routes.welcome);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: HCSpacing.xl),

                // Status card
                HCCard(
                  useGradient: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield, color: HCColors.accent, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Account Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: HCSpacing.md),
                      _buildStatusRow(
                        context,
                        'Email verified',
                        user?.verification?.email ?? false,
                      ),
                      _buildStatusRow(
                        context,
                        'Phone verified',
                        user?.verification?.phone ?? false,
                      ),
                      _buildStatusRow(
                        context,
                        'ID verified',
                        user?.verification?.governmentId ?? false,
                      ),
                      _buildStatusRow(
                        context,
                        'Profile complete',
                        user?.isProfileComplete ?? false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HCSpacing.lg),

                // Interests card
                if (user != null && user.interests.isNotEmpty) ...[
                  Text(
                    'Your interests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: HCSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) {
                      return Chip(
                        label: Text(interest.name),
                        avatar: interest.categoryIcon != null
                            ? Text(interest.categoryIcon!)
                            : null,
                      );
                    }).toList(),
                  ),
                ],

                const Spacer(),

                // Coming soon notice
                HCCard(
                  child: Row(
                    children: [
                      const Icon(Icons.rocket_launch, color: HCColors.primary),
                      const SizedBox(width: HCSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discovery coming soon',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Match suggestions and connections are being built next.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? HCColors.success : HCColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: completed ? HCColors.textPrimary : HCColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
