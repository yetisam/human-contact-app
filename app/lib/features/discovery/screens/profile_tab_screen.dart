import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
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
                CircleAvatar(
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
                const SizedBox(height: HCSpacing.md),
                Text(
                  user.firstName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (user.city != null)
                  Text(
                    '📍 ${user.city}',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                    const Icon(Icons.verified_user, color: HCColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Verification', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: HCSpacing.md),
                _statusRow(context, 'Email', user.emailVerified),
                _statusRow(context, 'Phone', user.phoneVerified),
                _statusRow(context, 'Government ID', user.verification?.governmentId ?? false),
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
                  Text('My purpose', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: HCSpacing.sm),
                  Text(
                    user.purposeStatement,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HCColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HCSpacing.md),
          ],

          // Interests
          if (user.interests.isNotEmpty) ...[
            Text('My interests', style: Theme.of(context).textTheme.titleMedium),
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
        ],
      ),
    );
  }

  Widget _statusRow(BuildContext context, String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? HCColors.success : HCColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: done ? HCColors.textPrimary : HCColors.textMuted)),
        ],
      ),
    );
  }
}
