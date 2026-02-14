import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/hc_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/verification_service.dart';
import '../widgets/otp_input.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  String _code = '';
  bool _isVerifying = false;
  bool _isSending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSending || _cooldown > 0) return;
    setState(() => _isSending = true);

    try {
      await ref.read(verificationServiceProvider).sendEmailCode();
      _startCooldown(60);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email')),
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
      await ref.read(verificationServiceProvider).verifyEmailCode(_code);
      await ref.read(authProvider.notifier).refreshProfile();

      if (mounted) {
        context.go(Routes.phoneVerify);
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
    final user = ref.watch(authProvider).user;

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

                const Icon(Icons.email_outlined, color: HCColors.primary, size: 48),
                const SizedBox(height: HCSpacing.lg),

                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: HCSpacing.sm),
                Text(
                  'We sent a 6-digit code to',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HCColors.textSecondary,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HCColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: HCSpacing.xxl),

                // OTP Input
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
                  label: 'Verify Email',
                  onPressed: _code.length == 6 ? _verify : null,
                  isLoading: _isVerifying,
                ),

                const SizedBox(height: HCSpacing.lg),

                // Resend
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

                const Spacer(),

                // Dev hint
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
