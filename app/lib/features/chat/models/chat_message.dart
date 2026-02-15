class ChatMessage {
  final String id;
  final String connectionId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final int? messagesRemaining;

  const ChatMessage({
    required this.id,
    required this.connectionId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.messagesRemaining,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      connectionId: json['connectionId'] ?? '',
      senderId: json['senderId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      messagesRemaining: json['messagesRemaining'],
    );
  }
}

class ChatParticipant {
  final String id;
  final String firstName;
  final String? avatarIcon;

  const ChatParticipant({
    required this.id,
    required this.firstName,
    this.avatarIcon,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      firstName: json['firstName'],
      avatarIcon: json['avatarIcon'],
    );
  }
}

class ChatConnectionInfo {
  final String id;
  final String status;
  final DateTime? chatOpenedAt;
  final DateTime? chatExpiresAt;
  final bool contactExchanged;
  final ChatParticipant requester;
  final ChatParticipant recipient;

  const ChatConnectionInfo({
    required this.id,
    required this.status,
    this.chatOpenedAt,
    this.chatExpiresAt,
    this.contactExchanged = false,
    required this.requester,
    required this.recipient,
  });

  factory ChatConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ChatConnectionInfo(
      id: json['id'],
      status: json['status'],
      chatOpenedAt: json['chatOpenedAt'] != null ? DateTime.parse(json['chatOpenedAt']) : null,
      chatExpiresAt: json['chatExpiresAt'] != null ? DateTime.parse(json['chatExpiresAt']) : null,
      contactExchanged: json['contactExchanged'] ?? false,
      requester: ChatParticipant.fromJson(json['participants']['requester']),
      recipient: ChatParticipant.fromJson(json['participants']['recipient']),
    );
  }

  bool get isExpired =>
      chatExpiresAt != null && DateTime.now().isAfter(chatExpiresAt!);

  Duration? get timeRemaining =>
      chatExpiresAt?.difference(DateTime.now());
}

class ChatLoadResponse {
  final ChatConnectionInfo connection;
  final List<ChatMessage> messages;
  final int myRemaining;
  final bool hasMore;

  const ChatLoadResponse({
    required this.connection,
    required this.messages,
    required this.myRemaining,
    this.hasMore = false,
  });

  factory ChatLoadResponse.fromJson(Map<String, dynamic> json) {
    return ChatLoadResponse(
      connection: ChatConnectionInfo.fromJson(json['connection']),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      myRemaining: json['myRemaining'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}
