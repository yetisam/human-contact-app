import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/hc_button.dart';
import '../../../widgets/hc_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/verification_service.dart';
import '../widgets/otp_input.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  String _code = '';
  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(verificationServiceProvider).sendPhoneCode(phone);
      setState(() => _codeSent = true);
      _startCooldown(60);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your phone')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startCooldown(int seconds) {
    setState(() => _cooldown = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    setState(() => _isVerifying = true);

    try {
      await ref.read(verificationServiceProvider).verifyPhoneCode(_code);
      await ref.read(authProvider.notifier).refreshProfile();

      if (mounted) {
        // Check if profile is complete, route accordingly
        final user = ref.read(authProvider).user;
        if (user != null && user.isProfileComplete) {
          context.go(Routes.home);
        } else {
          context.go(Routes.profileSetup);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(HCSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: HCSpacing.xl),

                const Icon(Icons.phone_android, color: HCColors.primary, size: 48),
                const SizedBox(height: HCSpacing.lg),

                Text(
                  'Verify your phone',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: HCSpacing.sm),
                Text(
                  _codeSent
                      ? 'Enter the 6-digit code we sent to ${_phoneController.text}'
                      : 'We\'ll send a verification code to confirm your number.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HCColors.textSecondary,
                  ),
                ),
                const SizedBox(height: HCSpacing.xxl),

                if (!_codeSent) ...[
                  // Phone number input
                  HCTextField(
                    label: 'Phone number',
                    hint: '+61 400 000 000',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: HCSpacing.xl),

                  HCButton(
                    label: 'Send Code',
                    onPressed: _sendCode,
                    isLoading: _isSending,
                  ),
                ] else ...[
                  // OTP input
                  OtpInput(
                    length: 6,
                    onCompleted: (code) {
                      _code = code;
                      _verify();
                    },
                    onChanged: (code) => _code = code,
                  ),
                  const SizedBox(height: HCSpacing.xl),

                  HCButton(
                    label: 'Verify Phone',
                    onPressed: _code.length == 6 ? _verify : null,
                    isLoading: _isVerifying,
                  ),
                  const SizedBox(height: HCSpacing.lg),

                  Center(
                    child: TextButton(
                      onPressed: _cooldown > 0 ? null : _sendCode,
                      child: Text(
                        _cooldown > 0
                            ? 'Resend code in ${_cooldown}s'
                            : 'Resend code',
                        style: TextStyle(
                          color: _cooldown > 0 ? HCColors.textMuted : HCColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Skip option (for dev/testing)
                Center(
                  child: TextButton(
                    onPressed: () {
                      final user = ref.read(authProvider).user;
                      if (user != null && user.isProfileComplete) {
                        context.go(Routes.home);
                      } else {
                        context.go(Routes.profileSetup);
                      }
                    },
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: HCColors.textMuted),
                    ),
                  ),
                ),

                Center(
                  child: Text(
                    'Check server console for the code (dev mode)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
