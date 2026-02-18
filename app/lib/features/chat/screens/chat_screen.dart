import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../widgets/hc_card.dart';
import '../../../core/websocket/ws_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String connectionId;

  const ChatScreen({super.key, required this.connectionId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  ChatConnectionInfo? _connectionInfo;
  int _myRemaining = 0;
  bool _loading = true;
  bool _sending = false;
  bool _otherTyping = false;
  Timer? _expiryTimer;
  Timer? _typingTimer;
  StreamSubscription? _wsSub;
  String? _myUserId;
  bool _showScrollToBottomFab = false;
  final Set<String> _visibleTimestamps = {};

  @override
  void initState() {
    super.initState();
    _loadChat();
    _connectWebSocket();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final isAtBottom = _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100;
    
    if (_showScrollToBottomFab && isAtBottom) {
      setState(() => _showScrollToBottomFab = false);
    } else if (!_showScrollToBottomFab && !isAtBottom && _messages.isNotEmpty) {
      setState(() => _showScrollToBottomFab = true);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _expiryTimer?.cancel();
    _typingTimer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      final response = await ref.read(chatServiceProvider).getMessages(widget.connectionId);
      final auth = ref.read(authProvider);
      if (mounted) {
        setState(() {
          _connectionInfo = response.connection;
          _messages = response.messages;
          _myRemaining = response.myRemaining;
          _myUserId = auth.user?.id;
          _loading = false;
        });
        _scrollToBottom();
        _startExpiryTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat: $e')),
        );
      }
    }
  }

  void _connectWebSocket() {
    final ws = ref.read(wsServiceProvider);
    ws.connect();

    _wsSub = ws.messages.listen((message) {
      final type = message['type'] as String?;

      switch (type) {
        case 'chat:message':
          final data = message['data'] as Map<String, dynamic>;
          if (data['connectionId'] == widget.connectionId) {
            final msg = ChatMessage.fromJson(data);
            setState(() {
              _messages.add(msg);
              _otherTyping = false;
              // Update remaining if it's our message
              if (msg.senderId == _myUserId && msg.messagesRemaining != null) {
                _myRemaining = msg.messagesRemaining!;
              }
            });
            _scrollToBottom();
          }
          break;

        case 'chat:typing':
          if (message['connectionId'] == widget.connectionId &&
              message['userId'] != _myUserId) {
            setState(() => _otherTyping = true);
            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _otherTyping = false);
            });
          }
          break;

        case 'chat:expired':
          if (message['connectionId'] == widget.connectionId) {
            setState(() {
              _connectionInfo = _connectionInfo != null
                  ? ChatConnectionInfo(
                      id: _connectionInfo!.id,
                      status: 'EXPIRED',
                      chatOpenedAt: _connectionInfo!.chatOpenedAt,
                      chatExpiresAt: _connectionInfo!.chatExpiresAt,
                      requester: _connectionInfo!.requester,
                      recipient: _connectionInfo!.recipient,
                    )
                  : null;
            });
          }
          break;

        case 'chat:limit_reached':
          if (message['connectionId'] == widget.connectionId) {
            setState(() => _myRemaining = 0);
          }
          break;
      }
    });
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {}); // Refresh expiry display
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _sending || _myRemaining <= 0) return;

    setState(() => _sending = true);
    _messageController.clear();

    final ws = ref.read(wsServiceProvider);

    if (ws.isConnected) {
      // Send via WebSocket (real-time)
      ws.sendChatMessage(widget.connectionId, content);
      setState(() => _sending = false);
    } else {
      // Fallback to HTTP
      try {
        final msg = await ref.read(chatServiceProvider).sendMessage(
          widget.connectionId,
          content,
        );
        setState(() {
          _messages.add(msg);
          _myRemaining = msg.messagesRemaining ?? (_myRemaining - 1);
          _sending = false;
        });
        _scrollToBottom();
      } catch (e) {
        setState(() => _sending = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      ref.read(wsServiceProvider).sendTyping(widget.connectionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: HCColors.bgGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final info = _connectionInfo;
    final isExpired = info?.isExpired ?? false;
    final canSend = !isExpired && _myRemaining > 0 && info?.status == 'ACTIVE';

    // Figure out the other person's name
    final otherPerson = info != null
        ? (info.requester.id == _myUserId ? info.recipient : info.requester)
        : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Chat header
              _buildHeader(otherPerson, info),

              // Expiry/limit banner
              if (info != null) _buildStatusBanner(info, isExpired),

              // Exchange CTA banner (shows when messages running low)
              _buildExchangeBanner(),

              // Messages
              Expanded(
                child: Stack(
                  children: [
                    _messages.isEmpty
                        ? _buildEmptyChat(otherPerson)
                        : _buildMessageList(),
                    
                    // Scroll to bottom FAB
                    if (_showScrollToBottomFab)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: AnimatedOpacity(
                          opacity: _showScrollToBottomFab ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: FloatingActionButton.small(
                            onPressed: () {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                            backgroundColor: HCColors.primary,
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Typing indicator
              if (_otherTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${otherPerson?.firstName ?? 'They'} is typing...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HCColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // Input bar or zero messages CTA
              _myRemaining == 0 ? _buildZeroMessagesCTA() : _buildInputBar(canSend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ChatParticipant? other, ChatConnectionInfo? info) {
    return Column(
      children: [
        // Main header — clean: back, avatar, name, exchange button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: HCColors.primary.withValues(alpha: 0.2),
                child: Text(
                  other?.firstName[0].toUpperCase() ?? '?',
                  style: const TextStyle(color: HCColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  other?.firstName ?? 'Chat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _buildExchangeHeaderButton(),
            ],
          ),
        ),
        // Info bar — timer and messages remaining
        Container(
          padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg, vertical: 6),
          decoration: BoxDecoration(
            color: HCColors.bgCard,
            border: Border(
              bottom: BorderSide(color: HCColors.border.withValues(alpha: 0.3), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Time remaining
              if (info?.timeRemaining != null && !info!.isExpired) ...[
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: info.timeRemaining!.inHours < 6 ? HCColors.error : HCColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimeRemaining(info.timeRemaining!),
                  style: TextStyle(
                    fontSize: 12,
                    color: info.timeRemaining!.inHours < 6 ? HCColors.error : HCColors.textMuted,
                  ),
                ),
              ],
              const Spacer(),
              // Messages remaining
              Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: _myRemaining > 3 ? HCColors.textMuted : HCColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '$_myRemaining messages left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _myRemaining > 3 ? HCColors.textMuted : HCColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeHeaderButton() {
    return InkWell(
      onTap: () => context.push('/exchange/${widget.connectionId}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [HCColors.accent, Color(0xFFE88B00)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Exchange',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prominent exchange CTA shown when messages are running low
  Widget _buildExchangeBanner() {
    if (_myRemaining > 5 || _connectionInfo?.isExpired == true) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.push('/exchange/${widget.connectionId}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: HCSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HCColors.accent.withValues(alpha: 0.15),
              HCColors.primary.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz, color: HCColors.accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _myRemaining <= 2 ? 'Running out of messages!' : 'Ready to connect outside the app?',
                    style: const TextStyle(
                      color: HCColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'Tap to exchange real contact details',
                    style: TextStyle(color: HCColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: HCColors.accent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ChatConnectionInfo info, bool isExpired) {
    if (isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: HCSpacing.lg),
        color: HCColors.error.withValues(alpha: 0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, color: HCColors.error, size: 16),
            SizedBox(width: 6),
            Text(
              'Chat window has expired',
              style: TextStyle(color: HCColors.error, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_myRemaining <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: HCSpacing.lg),
        color: HCColors.accent.withValues(alpha: 0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, color: HCColors.accent, size: 16),
            SizedBox(width: 6),
            Text(
              'You\'ve used all your messages. Exchange contacts to keep talking!',
              style: TextStyle(color: HCColors.accent, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyChat(ChatParticipant? other) {
    return Center(
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
              child: const Icon(Icons.waving_hand, color: HCColors.primary, size: 48),
            ),
            const SizedBox(height: HCSpacing.lg),
            Text(
              'Say hello! You have 10 messages and 48 hours to connect.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HCColors.textPrimary,
              ),
            ),
            const SizedBox(height: HCSpacing.sm),
            Text(
              'Make each message count!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HCColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: HCSpacing.md, vertical: HCSpacing.sm),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == _myUserId;
        final showTimestamp = index == 0 ||
            msg.createdAt.difference(_messages[index - 1].createdAt).inMinutes > 5;

        return Column(
          children: [
            if (showTimestamp)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatTimestamp(msg.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HCColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            _buildBubble(msg, isMe),
          ],
        );
      },
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe) {
    final showThisTimestamp = _visibleTimestamps.contains(msg.id);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (showThisTimestamp) {
                  _visibleTimestamps.remove(msg.id);
                } else {
                  _visibleTimestamps.add(msg.id);
                }
              });
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? HCColors.primary
                    : HCColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isMe ? Colors.white : HCColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          // Show timestamp when tapped
          if (showThisTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                _formatDetailedTimestamp(msg.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HCColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZeroMessagesCTA() {
    return Padding(
      padding: const EdgeInsets.all(HCSpacing.md),
      child: HCCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HCColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.message,
                    color: HCColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: HCSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You've used all your messages!",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HCColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Exchange contacts to keep talking.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HCColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: HCSpacing.md),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HCColors.accent, Color(0xFFE88B00)],
                ),
                borderRadius: BorderRadius.circular(HCRadius.md),
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/exchange/${widget.connectionId}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HCRadius.md),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                label: const Text(
                  'Exchange Contacts',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool canSend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HCSpacing.md, vertical: HCSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: HCColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: canSend,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onChanged: _onTextChanged,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: HCColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                hintText: canSend ? 'Type a message...' : 'Chat ended',
                hintStyle: const TextStyle(color: HCColors.textMuted),
                filled: true,
                fillColor: HCColors.bgInput,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: canSend && !_sending ? HCColors.primary : HCColors.bgInput,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: canSend && !_sending ? _sendMessage : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.send,
                  color: canSend && !_sending ? Colors.white : HCColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(Duration remaining) {
    if (remaining.isNegative) return 'Expired';
    if (remaining.inHours >= 1) return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
    return '${remaining.inMinutes}m remaining';
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }

  String _formatDetailedTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (diff.inDays == 0) {
      return time;
    } else if (diff.inDays == 1) {
      return 'Yesterday $time';
    } else {
      return '${dt.day}/${dt.month} $time';
    }
  }
}
