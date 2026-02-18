import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../widgets/hc_button.dart';
import '../../../widgets/hc_card.dart';
import '../../../widgets/hc_shimmer.dart';
import '../models/match_suggestion.dart';
import '../services/discovery_service.dart';
import '../../auth/providers/auth_provider.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

enum FilterType { all, highMatch, nearby }

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  List<MatchSuggestion> _matches = [];
  List<MatchSuggestion> _filteredMatches = [];
  FilterType _selectedFilter = FilterType.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ref.read(discoveryServiceProvider).getSuggestions();
      if (mounted) {
        setState(() {
          _matches = response.matches;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final user = ref.read(authProvider).user;
    final userCity = user?.city;
    
    switch (_selectedFilter) {
      case FilterType.all:
        _filteredMatches = _matches;
        break;
      case FilterType.highMatch:
        _filteredMatches = _matches.where((match) => match.scorePercent >= 70).toList();
        break;
      case FilterType.nearby:
        _filteredMatches = _matches.where((match) => 
          match.city != null && userCity != null && match.city == userCity
        ).toList();
        break;
    }
  }

  void _onFilterChanged(FilterType filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilter();
  }

  void _showConnectDialog(MatchSuggestion match) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HCColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: HCSpacing.lg,
          right: HCSpacing.lg,
          top: HCSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + HCSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect with ${match.firstName}',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: HCSpacing.sm),
            Text(
              'Write a brief introduction (20-200 characters). Be genuine!',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: HCColors.textSecondary,
              ),
            ),
            const SizedBox(height: HCSpacing.md),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              autofocus: true,
              style: const TextStyle(color: HCColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Hey ${match.firstName}! I noticed we both enjoy...',
                filled: true,
                fillColor: HCColors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HCRadius.md),
                  borderSide: const BorderSide(color: HCColors.border),
                ),
              ),
            ),
            const SizedBox(height: HCSpacing.md),
            HCButton(
              label: 'Send Connection Request',
              icon: Icons.send,
              onPressed: () async {
                final message = controller.text.trim();
                if (message.length < 20) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('At least 20 characters please')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _sendRequest(match, message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(MatchSuggestion match, String message) async {
    try {
      await ref.read(discoveryServiceProvider).sendConnectionRequest(
        recipientId: match.id,
        introMessage: message,
      );
      if (mounted) {
        // Remove from both lists
        setState(() {
          _matches.removeWhere((m) => m.id == match.id);
          _filteredMatches.removeWhere((m) => m.id == match.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${match.firstName}! 🤝')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(HCSpacing.md),
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: HCSpacing.md),
                child: HCShimmerElements.matchCard(),
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: HCColors.error, size: 48),
                  const SizedBox(height: HCSpacing.md),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: HCSpacing.sm),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HCColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: HCSpacing.md),
                  HCButton(label: 'Retry', icon: Icons.refresh, onPressed: _loadSuggestions),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_matches.isEmpty) {
      return Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(HCSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(HCSpacing.lg),
                      decoration: BoxDecoration(
                        color: HCColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(HCRadius.full),
                      ),
                      child: const Icon(Icons.person_search, color: HCColors.primary, size: 48),
                    ),
                    const SizedBox(height: HCSpacing.lg),
                    Text(
                      'No matches yet — complete your profile for better results',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HCColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: HCSpacing.sm),
                    Text(
                      'As more people join, you\'ll see matches here based on shared interests and location.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HCColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: HCSpacing.lg),
                    HCButton(
                      label: 'Complete Profile',
                      icon: Icons.person,
                      onPressed: () {
                        // Navigate to profile completion
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile completion coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: HCSpacing.md),
                    HCOutlineButton(label: 'Refresh', onPressed: _loadSuggestions),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_filteredMatches.isEmpty) {
      return Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(HCSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(HCSpacing.lg),
                      decoration: BoxDecoration(
                        color: HCColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(HCRadius.full),
                      ),
                      child: const Icon(Icons.filter_list_off, color: HCColors.primary, size: 48),
                    ),
                    const SizedBox(height: HCSpacing.lg),
                    Text(
                      'No matches found with this filter',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HCColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: HCSpacing.sm),
                    Text(
                      'Try a different filter or refresh to see all matches.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HCColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildFilterRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSuggestions,
            child: ListView.builder(
              padding: const EdgeInsets.all(HCSpacing.md),
              itemCount: _filteredMatches.length,
              itemBuilder: (context, index) => _buildMatchCard(_filteredMatches[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HCSpacing.lg,
        vertical: HCSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: HCColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HCColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: HCSpacing.sm),
          Expanded(
            child: Row(
              children: [
                _buildFilterChip('All', FilterType.all),
                const SizedBox(width: HCSpacing.sm),
                _buildFilterChip('High Match', FilterType.highMatch),
                const SizedBox(width: HCSpacing.sm),
                _buildFilterChip('Nearby', FilterType.nearby),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterType type) {
    final isSelected = _selectedFilter == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? HCColors.textPrimary : HCColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _onFilterChanged(type);
      },
      backgroundColor: HCColors.bgInput,
      selectedColor: HCColors.primary,
      side: BorderSide(
        color: isSelected ? HCColors.primary : HCColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HCRadius.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildMatchCard(MatchSuggestion match) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HCSpacing.md),
      child: HCCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Avatar placeholder
                CircleAvatar(
                  radius: 24,
                  backgroundColor: HCColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    match.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: HCColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: HCSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.firstName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (match.city != null)
                        Text(
                          '📍 ${match.city}${match.state != null ? ', ${match.state}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                // Match score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor(match.scorePercent).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${match.scorePercent}%',
                    style: TextStyle(
                      color: _scoreColor(match.scorePercent),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: HCSpacing.md),

            // Purpose statement
            if (match.purposeStatement != null && match.purposeStatement!.isNotEmpty)
              Text(
                '"${match.purposeStatement}"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: HCColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: HCSpacing.md),

            // Match quality indicators
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Shared interests badge
                if (match.sharedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HCColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HCColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${match.sharedCount} shared interests',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: HCColors.success,
                      ),
                    ),
                  ),
                
                // Same city badge
                if (match.city != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HCColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HCColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Same city',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: HCColors.primary,
                      ),
                    ),
                  ),
              ],
            ),

            if (match.sharedInterests.isNotEmpty) ...[
              const SizedBox(height: HCSpacing.md),
              Text(
                'Shared interests:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: HCColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: match.sharedInterests.take(5).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HCColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${interest.categoryIcon ?? ''} ${interest.name}',
                      style: const TextStyle(fontSize: 12, color: HCColors.textPrimary),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: HCSpacing.md),

            // Meeting preference indicator
            if (match.meetingPreference)
              Padding(
                padding: const EdgeInsets.only(bottom: HCSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.handshake, size: 16, color: HCColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Prefers meeting in person first',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HCColors.accent,
                      ),
                    ),
                  ],
                ),
              ),

            // Connect button
            HCButton(
              label: 'Connect',
              icon: Icons.person_add,
              onPressed: () => _showConnectDialog(match),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int percent) {
    if (percent >= 70) return HCColors.success;
    if (percent >= 40) return HCColors.accent;
    return HCColors.textMuted;
  }
}
