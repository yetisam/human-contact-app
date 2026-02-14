import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/hc_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo area
                _buildLogo(),
                const SizedBox(height: HCSpacing.xl),

                // Tagline
                Text(
                  'The place to meet\nreal humans.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: HCSpacing.md),

                // Subtitle
                Text(
                  'Safe. Verified. Real connections.\nNot another social network.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HCColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 2),

                // Value propositions
                _buildValueProp(
                  Icons.verified_user,
                  'Verified identities only',
                ),
                const SizedBox(height: HCSpacing.sm),
                _buildValueProp(
                  Icons.handshake,
                  'Exchange contact info safely',
                ),
                const SizedBox(height: HCSpacing.sm),
                _buildValueProp(
                  Icons.shield,
                  'Privacy by design — no selfies required',
                ),

                const Spacer(),

                // CTA Buttons
                HCButton(
                  label: 'Get Started',
                  onPressed: () => context.push(Routes.register),
                ),
                const SizedBox(height: HCSpacing.md),
                HCOutlineButton(
                  label: 'I already have an account',
                  onPressed: () => context.push(Routes.login),
                ),

                const SizedBox(height: HCSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left figure (blue)
          Icon(
            Icons.person,
            size: 64,
            color: HCColors.primary,
          ),
          const SizedBox(width: 4),
          // Handshake
          Icon(
            Icons.handshake,
            size: 32,
            color: HCColors.textMuted,
          ),
          const SizedBox(width: 4),
          // Right figure (orange)
          Icon(
            Icons.person,
            size: 64,
            color: HCColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildValueProp(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: HCColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(HCRadius.sm),
          ),
          child: Icon(icon, color: HCColors.primary, size: 20),
        ),
        const SizedBox(width: HCSpacing.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: HCColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
