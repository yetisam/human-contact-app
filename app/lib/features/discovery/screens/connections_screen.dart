import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../widgets/hc_button.dart';
import '../../../widgets/hc_card.dart';
import '../services/discovery_service.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _received = [];
  List<dynamic> _sent = [];
  List<dynamic> _active = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(discoveryServiceProvider);

      final results = await Future.wait([
        service.getConnections(type: 'received', status: 'PENDING'),
        service.getConnections(type: 'sent', status: 'PENDING'),
        service.getConnections(status: 'ACTIVE'),
      ]);

      if (mounted) {
        setState(() {
          _received = results[0]['connections'] as List;
          _sent = results[1]['connections'] as List;
          _active = results[2]['connections'] as List;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(String connectionId) async {
    try {
      await ref.read(discoveryServiceProvider).acceptConnection(connectionId);
      _loadConnections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection accepted! Chat window is open for 48 hours 💬')),
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

  Future<void> _decline(String connectionId) async {
    try {
      await ref.read(discoveryServiceProvider).declineConnection(connectionId);
      _loadConnections();
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: HCColors.primary,
          unselectedLabelColor: HCColors.textMuted,
          indicatorColor: HCColors.primary,
          tabs: [
            Tab(text: 'Received (${_received.length})'),
            Tab(text: 'Sent (${_sent.length})'),
            Tab(text: 'Active (${_active.length})'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceivedList(),
                    _buildSentList(),
                    _buildActiveList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HCSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, color: HCColors.textMuted, size: 48),
            const SizedBox(height: HCSpacing.md),
            Text(message, style: TextStyle(color: HCColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedList() {
    if (_received.isEmpty) return _buildEmptyState('No pending requests');

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: const EdgeInsets.all(HCSpacing.md),
        itemCount: _received.length,
        itemBuilder: (context, index) {
          final conn = _received[index];
          final requester = conn['requester'];
          return Padding(
            padding: const EdgeInsets.only(bottom: HCSpacing.md),
            child: HCCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: HCColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          (requester['firstName'] as String)[0].toUpperCase(),
                          style: const TextStyle(color: HCColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: HCSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(requester['firstName'], style: Theme.of(context).textTheme.titleMedium),
                            if (requester['city'] != null)
                              Text('📍 ${requester['city']}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HCSpacing.sm),
                  Text(
                    '"${conn['introMessage']}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: HCColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: HCSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: HCOutlineButton(
                          label: 'Decline',
                          onPressed: () => _decline(conn['id']),
                        ),
                      ),
                      const SizedBox(width: HCSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: HCButton(
                          label: 'Accept',
                          icon: Icons.check,
                          onPressed: () => _accept(conn['id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentList() {
    if (_sent.isEmpty) return _buildEmptyState('No pending sent requests');

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: const EdgeInsets.all(HCSpacing.md),
        itemCount: _sent.length,
        itemBuilder: (context, index) {
          final conn = _sent[index];
          final recipient = conn['recipient'];
          return Padding(
            padding: const EdgeInsets.only(bottom: HCSpacing.md),
            child: HCCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: HCColors.accent.withValues(alpha: 0.2),
                    child: Text(
                      (recipient['firstName'] as String)[0].toUpperCase(),
                      style: const TextStyle(color: HCColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: HCSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipient['firstName'], style: Theme.of(context).textTheme.titleMedium),
                        Text('Waiting for response...', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.hourglass_empty, color: HCColors.textMuted, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveList() {
    if (_active.isEmpty) return _buildEmptyState('No active connections yet');

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: const EdgeInsets.all(HCSpacing.md),
        itemCount: _active.length,
        itemBuilder: (context, index) {
          final conn = _active[index];
          // Figure out who the other person is
          final requester = conn['requester'];
          final recipient = conn['recipient'];
          // TODO: compare with current user ID to determine other person

          return Padding(
            padding: const EdgeInsets.only(bottom: HCSpacing.md),
            child: HCCard(
              useGradient: true,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: HCColors.success.withValues(alpha: 0.2),
                    child: const Icon(Icons.chat_bubble, color: HCColors.success, size: 20),
                  ),
                  const SizedBox(width: HCSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${requester['firstName']} ↔ ${recipient['firstName']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (conn['chatExpiresAt'] != null)
                          Text(
                            'Chat expires: ${_formatExpiry(conn['chatExpiresAt'])}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HCColors.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: HCColors.primary, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatExpiry(String expiryStr) {
    final expiry = DateTime.parse(expiryStr);
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inHours > 0) return '${remaining.inHours}h remaining';
    return '${remaining.inMinutes}m remaining';
  }
}
