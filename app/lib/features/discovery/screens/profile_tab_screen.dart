import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/hc_card.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(HCSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                // Avatar with verification ring
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: user.isVerified ? HCColors.success : HCColors.accent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: HCColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          user.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: HCColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (user.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: HCColors.bgDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, color: HCColors.success, size: 22),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: HCSpacing.md),
                Text(
                  user.firstName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (user.city != null)
                  Text(
                    '📍 ${user.city}${user.state != null ? ', ${user.state}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: HCSpacing.sm),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isVerified
                        ? HCColors.success.withValues(alpha: 0.15)
                        : HCColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(HCRadius.xl),
                  ),
                  child: Text(
                    user.isVerified ? '✓ Verified' : '⏳ Pending Verification',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isVerified ? HCColors.success : HCColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: HCSpacing.md),
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push(Routes.profileSetup),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HCColors.primary,
                        side: const BorderSide(color: HCColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: HCSpacing.sm),
                    IconButton(
                      onPressed: () => context.push(Routes.settings),
                      icon: const Icon(Icons.settings),
                      color: HCColors.textMuted,
                      tooltip: 'Settings',
                      style: IconButton.styleFrom(
                        backgroundColor: HCColors.bgCard,
                        side: const BorderSide(color: HCColors.border),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: HCSpacing.xl),

          // Verification status
          HCCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, color: HCColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Trust & Verification', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: HCSpacing.md),
                _verificationRow(context, 'Email verified', user.emailVerified, Icons.email),
                _verificationRow(context, 'Phone verified', user.phoneVerified, Icons.phone),
                _verificationRow(context, 'ID verified', user.verification?.governmentId ?? false, Icons.badge),
              ],
            ),
          ),

          const SizedBox(height: HCSpacing.md),

          // Purpose statement
          if (user.purposeStatement.isNotEmpty) ...[
            HCCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_quote, color: HCColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text('Why I\'m here', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: HCSpacing.sm),
                  Text(
                    user.purposeStatement,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: HCColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HCSpacing.md),
          ],

          // Interests
          if (user.interests.isNotEmpty) ...[
            HCCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.interests, color: HCColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('My interests', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        '${user.interests.length} selected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: HCSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: HCColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(HCRadius.xl),
                          border: Border.all(color: HCColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '${interest.categoryIcon ?? ''} ${interest.name}',
                          style: const TextStyle(fontSize: 13, color: HCColors.textPrimary),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HCSpacing.md),
          ],

          // No-photo explanation
          HCCard(
            child: Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: HCColors.textMuted.withValues(alpha: 0.5), size: 28),
                const SizedBox(width: HCSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No photos by design', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'We focus on who you are, not how you look. Connect through shared interests and real conversations.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HCColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: HCSpacing.xl),

          // Account actions
          Center(
            child: TextButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(Routes.welcome);
              },
              child: const Text('Sign Out', style: TextStyle(color: HCColors.error)),
            ),
          ),
          const SizedBox(height: HCSpacing.lg),
        ],
      ),
    );
  }

  Widget _verificationRow(BuildContext context, String label, bool done, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? HCColors.success.withValues(alpha: 0.15) : HCColors.bgInput,
            ),
            child: Icon(
              done ? Icons.check : icon,
              color: done ? HCColors.success : HCColors.textMuted,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: done ? HCColors.textPrimary : HCColors.textMuted,
              fontWeight: done ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (done)
            const Icon(Icons.check_circle, color: HCColors.success, size: 16),
        ],
      ),
    );
  }
}
