import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

                // Logo + tagline — vertically centered together
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: HCColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: HCColors.primary.withValues(alpha: 0.15),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: HCColors.accent.withValues(alpha: 0.08),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              HCColors.bgCard.withValues(alpha: 0.8),
                              HCColors.bgDark.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/logo-stacked.svg',
                          width: 260,
                          height: 260,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: HCSpacing.lg),
                      Text(
                        'The place to meet\nreal humans.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: HCSpacing.md),
                      Text(
                        'Safe. Verified. Real connections.\nNot another social network.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: HCColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
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
                  label: 'Sign In',
                  onPressed: () => context.push(Routes.login),
                ),

                const SizedBox(height: HCSpacing.md),

                // Beta badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: HCColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(HCRadius.xl),
                    border: Border.all(color: HCColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'BETA v1.0',
                    style: TextStyle(color: HCColors.accent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                ),

                const SizedBox(height: HCSpacing.lg),
              ],
            ),
          ),
        ),
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
