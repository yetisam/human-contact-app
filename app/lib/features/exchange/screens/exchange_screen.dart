import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../widgets/hc_button.dart';
import '../../../widgets/hc_card.dart';
import '../services/exchange_service.dart';

class ExchangeScreen extends ConsumerStatefulWidget {
  final String connectionId;

  const ExchangeScreen({super.key, required this.connectionId});

  @override
  ConsumerState<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends ConsumerState<ExchangeScreen> {
  // Request fields
  bool _shareEmail = true;
  bool _sharePhone = false;
  bool _wantsEmail = true;
  bool _wantsPhone = false;

  // State
  String _status = 'loading'; // loading, request, pending, approve, reveal, expired
  String? _exchangeId;
  bool _isRequester = false;
  bool _isSending = false;

  // Reveal data
  Map<String, dynamic>? _revealData;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  // Approve fields (for recipient)
  bool _approveShareEmail = true;
  bool _approveSharePhone = false;

  @override
  void initState() {
    super.initState();
    _checkExchangeStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExchangeStatus() async {
    try {
      final data = await ref.read(exchangeServiceProvider).getExchangeStatus(widget.connectionId);
      if (!mounted) return;

      if (data['hasExchange'] == true) {
        _exchangeId = data['id'];
        _isRequester = data['isRequester'] ?? false;
        final status = data['status'] as String;

        if (status == 'APPROVED') {
          setState(() => _status = 'reveal');
          _loadReveal();
        } else if (status == 'PENDING') {
          setState(() => _status = _isRequester ? 'pending' : 'approve');
        } else {
          setState(() => _status = 'request');
        }
      } else {
        setState(() => _status = 'request');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'request');
    }
  }

  Future<void> _sendRequest() async {
    if (!_shareEmail && !_sharePhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share at least one contact method')),
      );
      return;
    }
    if (!_wantsEmail && !_wantsPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request at least one contact method')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final result = await ref.read(exchangeServiceProvider).requestExchange(
        connectionId: widget.connectionId,
        shareEmail: _shareEmail,
        sharePhone: _sharePhone,
        wantsEmail: _wantsEmail,
        wantsPhone: _wantsPhone,
      );
      _exchangeId = result['id'];
      _isRequester = true;
      setState(() => _status = 'pending');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _approve() async {
    if (!_approveShareEmail && !_approveSharePhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share at least one contact method')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(exchangeServiceProvider).approveExchange(
        exchangeId: _exchangeId!,
        shareEmail: _approveShareEmail,
        sharePhone: _approveSharePhone,
      );
      setState(() => _status = 'reveal');
      _loadReveal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _decline() async {
    try {
      await ref.read(exchangeServiceProvider).declineExchange(_exchangeId!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _loadReveal() async {
    try {
      final data = await ref.read(exchangeServiceProvider).getReveal(_exchangeId!);
      if (!mounted) return;

      setState(() => _revealData = data);

      // Start countdown timer
      if (data['revealExpiresAt'] != null) {
        final expiry = DateTime.parse(data['revealExpiresAt']);
        _startCountdown(expiry);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'expired');
      }
    }
  }

  void _startCountdown(DateTime expiry) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiry.difference(DateTime.now());
      if (remaining.isNegative) {
        _countdownTimer?.cancel();
        if (mounted) setState(() => _timeRemaining = Duration.zero);
      } else {
        if (mounted) setState(() => _timeRemaining = remaining);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(HCSpacing.md),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                    Text('Contact Exchange', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(HCSpacing.lg),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case 'loading':
        return const Center(child: CircularProgressIndicator());
      case 'request':
        return _buildRequestForm();
      case 'pending':
        return _buildPendingState();
      case 'approve':
        return _buildApproveForm();
      case 'reveal':
        return _buildReveal();
      case 'expired':
        return _buildExpired();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 1: Request form — choose what to share and what you want
  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.swap_horiz, color: HCColors.primary, size: 48),
        const SizedBox(height: HCSpacing.lg),
        Text('Exchange contact info', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: HCSpacing.sm),
        Text(
          'Choose what you\'d like to share and what you\'d like to receive. '
          'Both sides must approve before anything is revealed.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HCColors.textSecondary),
        ),
        const SizedBox(height: HCSpacing.xl),

        // What I'll share
        Text('I\'ll share:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HCSpacing.sm),
        _buildToggle('Email address', _shareEmail, (v) => setState(() => _shareEmail = v), Icons.email),
        _buildToggle('Phone number', _sharePhone, (v) => setState(() => _sharePhone = v), Icons.phone),

        const SizedBox(height: HCSpacing.lg),

        // What I want
        Text('I\'d like their:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HCSpacing.sm),
        _buildToggle('Email address', _wantsEmail, (v) => setState(() => _wantsEmail = v), Icons.email),
        _buildToggle('Phone number', _wantsPhone, (v) => setState(() => _wantsPhone = v), Icons.phone),

        const SizedBox(height: HCSpacing.xl),
        HCButton(
          label: 'Send Exchange Request',
          icon: Icons.swap_horiz,
          onPressed: _sendRequest,
          isLoading: _isSending,
        ),
      ],
    );
  }

  /// Waiting for the other person
  Widget _buildPendingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_top, color: HCColors.accent, size: 64),
          const SizedBox(height: HCSpacing.lg),
          Text('Waiting for approval', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: HCSpacing.sm),
          Text(
            'Your exchange request has been sent. You\'ll be notified when they respond.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HCColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Step 2: Approve form (for recipient)
  Widget _buildApproveForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.swap_horiz, color: HCColors.accent, size: 48),
        const SizedBox(height: HCSpacing.lg),
        Text('Exchange request received!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: HCSpacing.sm),
        Text(
          'Someone wants to exchange contact info with you. '
          'Choose what you\'d like to share back.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HCColors.textSecondary),
        ),
        const SizedBox(height: HCSpacing.xl),

        Text('I\'ll share:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HCSpacing.sm),
        _buildToggle('Email address', _approveShareEmail, (v) => setState(() => _approveShareEmail = v), Icons.email),
        _buildToggle('Phone number', _approveSharePhone, (v) => setState(() => _approveSharePhone = v), Icons.phone),

        const SizedBox(height: HCSpacing.xl),
        HCButton(
          label: 'Approve Exchange',
          icon: Icons.check,
          onPressed: _approve,
          isLoading: _isSending,
        ),
        const SizedBox(height: HCSpacing.md),
        Center(
          child: TextButton(
            onPressed: _decline,
            child: const Text('Decline', style: TextStyle(color: HCColors.error)),
          ),
        ),
      ],
    );
  }

  /// Step 3: The big reveal!
  Widget _buildReveal() {
    if (_revealData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final otherPerson = _revealData!['otherPerson'] as Map<String, dynamic>;
    final contact = otherPerson['contact'] as Map<String, dynamic>;
    final myShared = _revealData!['myShared'] as Map<String, dynamic>;
    final isRevealActive = _timeRemaining > Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Countdown banner
        if (isRevealActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HCSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [HCColors.primary.withValues(alpha: 0.3), HCColors.accent.withValues(alpha: 0.3)],
              ),
              borderRadius: BorderRadius.circular(HCRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  '${_timeRemaining.inMinutes}:${(_timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: HCColors.primary),
                ),
                const Text('Save these details before the timer runs out!', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),

        const SizedBox(height: HCSpacing.xl),
        const Icon(Icons.celebration, color: HCColors.accent, size: 48),
        const SizedBox(height: HCSpacing.md),
        Text('Contact revealed! 🎉', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: HCSpacing.sm),
        Text(
          '${otherPerson['firstName']}\'s contact info:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: HCSpacing.md),

        // Their contact details
        if (contact['email'] != null)
          _buildContactCard('Email', contact['email'] as String, Icons.email),
        if (contact['phone'] != null)
          _buildContactCard('Phone', contact['phone'] as String, Icons.phone),

        if (contact.isEmpty)
          HCCard(
            child: Text(
              'They didn\'t share any contact methods.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HCColors.textMuted),
            ),
          ),

        const SizedBox(height: HCSpacing.xl),

        // What I shared
        Text('You shared:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: HCSpacing.sm),
        if (myShared['email'] != null)
          Text('📧 ${myShared['email']}', style: Theme.of(context).textTheme.bodyMedium),
        if (myShared['phone'] != null)
          Text('📱 ${myShared['phone']}', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildExpired() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off, color: HCColors.error, size: 64),
          const SizedBox(height: HCSpacing.lg),
          Text('Exchange expired', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: HCSpacing.sm),
          Text(
            'The reveal window has closed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HCColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HCCard(
        child: Row(
          children: [
            Icon(icon, color: value ? HCColors.primary : HCColors.textMuted, size: 22),
            const SizedBox(width: HCSpacing.md),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            Switch(value: value, onChanged: onChanged, activeThumbColor: HCColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HCSpacing.sm),
      child: HCCard(
        useGradient: true,
        child: Row(
          children: [
            Icon(icon, color: HCColors.primary),
            const SizedBox(width: HCSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HCColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: HCColors.textMuted, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
