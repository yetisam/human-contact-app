import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../models/interest.dart';
import '../../../widgets/hc_button.dart';
import '../../../widgets/hc_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/profile_service.dart';
import '../../../widgets/hc_step_indicator.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1: About you
  final _purposeController = TextEditingController();
  final _cityController = TextEditingController();
  bool _meetingPreference = false;

  // Page 2: Interests
  List<InterestCategory> _categories = [];
  final Set<String> _selectedInterestIds = {};
  bool _loadingInterests = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    try {
      final categories = await ref.read(profileServiceProvider).getInterests();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingInterests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingInterests = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load interests: $e')),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_purposeController.text.trim().length < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purpose statement needs at least 50 characters')),
        );
        return;
      }
      if (_cityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your city')),
        );
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveProfile() async {
    if (_selectedInterestIds.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 interests')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = ref.read(authProvider);
      await ref.read(profileServiceProvider).setupProfile(
        firstName: auth.user?.firstName ?? '',
        purposeStatement: _purposeController.text.trim(),
        meetingPreference: _meetingPreference,
        interestIds: _selectedInterestIds.toList(),
        city: _cityController.text.trim(),
        state: 'QLD', // TODO: Add state picker
        country: 'AU',
      );

      // Refresh profile in auth state
      await ref.read(authProvider.notifier).refreshProfile();

      if (mounted) {
        context.go(Routes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _purposeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Onboarding step indicator
              const HCStepIndicator(currentStep: 2),

              // Profile sub-step indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg),
                child: Row(
                  children: [
                    _buildProgressDot(0),
                    const SizedBox(width: 8),
                    _buildProgressDot(1),
                    const Spacer(),
                    Text(
                      'Step ${_currentPage + 1} of 2',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildAboutPage(),
                    _buildInterestsPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    final isActive = _currentPage >= index;
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? HCColors.primary : HCColors.bgInput,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Page 1: About you
  Widget _buildAboutPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(HCSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about you', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: HCSpacing.sm),
          Text(
            'This helps people understand who you are and what you\'re looking for.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: HCColors.textSecondary),
          ),
          const SizedBox(height: HCSpacing.xl),

          HCTextField(
            label: 'Why are you seeking connection?',
            hint: 'e.g., Looking to meet genuine people for coffee and conversation',
            controller: _purposeController,
            maxLines: 3,
            maxLength: 200,
            validator: (v) => (v == null || v.length < 50) ? 'At least 50 characters' : null,
            onChanged: (value) => setState(() {}), // Trigger rebuild for character count
          ),
          // Character count
          Padding(
            padding: const EdgeInsets.only(left: HCSpacing.sm, top: 4),
            child: Text(
              '${_purposeController.text.length}/200 characters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _purposeController.text.length < 50 
                    ? HCColors.error 
                    : _purposeController.text.length >= 200 
                        ? HCColors.accent 
                        : HCColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: HCSpacing.md),

          HCTextField(
            label: 'City',
            hint: 'e.g., Brisbane',
            controller: _cityController,
            prefixIcon: Icons.location_city,
          ),
          const SizedBox(height: HCSpacing.lg),

          // Meeting preference toggle
          Container(
            padding: const EdgeInsets.all(HCSpacing.md),
            decoration: BoxDecoration(
              color: HCColors.bgCard,
              borderRadius: BorderRadius.circular(HCRadius.md),
              border: Border.all(color: HCColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I prefer to meet in person first',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Before exchanging contact information',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _meetingPreference,
                  onChanged: (v) => setState(() => _meetingPreference = v),
                  activeThumbColor: HCColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: HCSpacing.xl),
          HCButton(label: 'Continue', icon: Icons.arrow_forward, onPressed: _nextPage),
        ],
      ),
    );
  }

  /// Page 2: Pick your interests
  Widget _buildInterestsPage() {
    if (_loadingInterests) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pick your interests', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: HCSpacing.sm),
              Text(
                'Choose 3–10 interests. These help us find compatible people near you.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: HCColors.textSecondary),
              ),
              const SizedBox(height: HCSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_selectedInterestIds.length < 3 
                      ? HCColors.error 
                      : _selectedInterestIds.length >= 3 && _selectedInterestIds.length <= 10 
                          ? HCColors.success 
                          : HCColors.accent).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_selectedInterestIds.length < 3 
                        ? HCColors.error 
                        : _selectedInterestIds.length >= 3 && _selectedInterestIds.length <= 10 
                            ? HCColors.success 
                            : HCColors.accent).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_selectedInterestIds.length} of 3-10 selected',
                  style: TextStyle(
                    color: _selectedInterestIds.length < 3 
                        ? HCColors.error 
                        : _selectedInterestIds.length >= 3 && _selectedInterestIds.length <= 10 
                            ? HCColors.success 
                            : HCColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HCSpacing.md),

        // Interest categories
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _buildCategorySection(cat);
            },
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(HCSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: HCOutlineButton(label: 'Back', onPressed: _prevPage),
              ),
              const SizedBox(width: HCSpacing.md),
              Expanded(
                flex: 2,
                child: HCButton(
                  label: 'Complete Setup',
                  onPressed: _selectedInterestIds.length >= 3 ? _saveProfile : null,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(InterestCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HCSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${category.icon ?? ''} ${category.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: HCSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.interests.map((interest) {
              final selected = _selectedInterestIds.contains(interest.id);
              return FilterChip(
                label: Text(interest.name),
                selected: selected,
                onSelected: (isSelected) {
                  setState(() {
                    if (isSelected) {
                      if (_selectedInterestIds.length < 10) {
                        _selectedInterestIds.add(interest.id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Maximum 10 interests')),
                        );
                      }
                    } else {
                      _selectedInterestIds.remove(interest.id);
                    }
                  });
                },
                selectedColor: HCColors.primary.withValues(alpha: 0.3),
                checkmarkColor: HCColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
