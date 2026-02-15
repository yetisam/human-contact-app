import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
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

  @override
  void initState() {
    super.initState();
    _loadChat();
    _connectWebSocket();
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

              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyChat(otherPerson)
                    : _buildMessageList(),
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

              // Input bar
              _buildInputBar(canSend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ChatParticipant? other, ChatConnectionInfo? info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HCColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: HCColors.primary.withValues(alpha: 0.2),
            child: Text(
              other?.firstName[0].toUpperCase() ?? '?',
              style: const TextStyle(color: HCColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  other?.firstName ?? 'Chat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (info?.timeRemaining != null && !info!.isExpired)
                  Text(
                    _formatTimeRemaining(info.timeRemaining!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: info.timeRemaining!.inHours < 6 ? HCColors.error : HCColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          // Exchange contact button
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: HCColors.accent),
            tooltip: 'Exchange contacts',
            onPressed: () => context.push('/exchange/${widget.connectionId}'),
          ),
          // Messages remaining badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _myRemaining > 3
                  ? HCColors.primary.withValues(alpha: 0.2)
                  : HCColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_myRemaining left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _myRemaining > 3 ? HCColors.primary : HCColors.error,
              ),
            ),
          ),
        ],
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
            const Icon(Icons.chat_bubble_outline, color: HCColors.textMuted, size: 48),
            const SizedBox(height: HCSpacing.md),
            Text(
              'Say hello to ${other?.firstName ?? 'your match'}!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: HCSpacing.sm),
            Text(
              'You have 10 messages and 48 hours.\nMake them count!',
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
}
