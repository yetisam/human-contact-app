import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/hc_button.dart';
import '../../../widgets/hc_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
      );

      if (mounted) {
        context.go(Routes.profileSetup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HCSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: HCSpacing.lg),

                  Text(
                    'Create your account',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: HCSpacing.sm),
                  Text(
                    'Start your journey to real human connection.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: HCColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: HCSpacing.xl),

                  HCTextField(
                    label: 'First name',
                    hint: 'How people will see you',
                    controller: _firstNameController,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your first name';
                      }
                      if (value.trim().length > 50) {
                        return 'Name must be 50 characters or less';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: HCSpacing.md),

                  HCTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: HCSpacing.md),

                  HCTextField(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.next,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: HCColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a password';
                      if (value.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: HCSpacing.md),

                  HCTextField(
                    label: 'Confirm password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: HCColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: HCSpacing.lg),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24, height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                          activeColor: HCColors.primary,
                        ),
                      ),
                      const SizedBox(width: HCSpacing.sm),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: const [
                                TextSpan(text: 'Terms of Service', style: TextStyle(color: HCColors.primary)),
                                TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy', style: TextStyle(color: HCColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HCSpacing.xl),

                  HCButton(
                    label: 'Create Account',
                    onPressed: _agreedToTerms ? _register : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: HCSpacing.md),

                  Center(
                    child: TextButton(
                      onPressed: () => context.pushReplacement(Routes.login),
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: const TextStyle(color: HCColors.textMuted),
                          children: const [
                            TextSpan(text: 'Sign in', style: TextStyle(color: HCColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
