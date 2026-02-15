import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../storage/secure_storage.dart';

/// WebSocket connection manager
class WebSocketService {
  final SecureStorageService _storage;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;

  // Stream controllers for different message types
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;
  bool get isConnected => _isConnected;

  WebSocketService(this._storage);

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _storage.getAccessToken();
    if (token == null) return;

    final wsUrl = ApiConfig.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://')
        .replaceFirst('/api/v1', '');

    try {
      final uri = Uri.parse('$wsUrl/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _handleMessage(message);
          } catch (e) {
            debugPrint('WS parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('WS error: $error');
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      debugPrint('WebSocket connected');
    } catch (e) {
      debugPrint('WS connect error: $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    if (type == 'connected') {
      debugPrint('WS authenticated: ${message['userId']}');
      return;
    }

    _messageController.add(message);
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectionStateController.add(false);
    _channel = null;

    // Auto-reconnect with backoff
    if (_reconnectAttempts < _maxReconnectAttempts) {
      final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 30));
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        _reconnectAttempts++;
        connect();
      });
    }
  }

  /// Send a chat message
  void sendChatMessage(String connectionId, String content) {
    _send({
      'type': 'chat:send',
      'connectionId': connectionId,
      'content': content,
    });
  }

  /// Send typing indicator
  void sendTyping(String connectionId) {
    _send({
      'type': 'chat:typing',
      'connectionId': connectionId,
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Disconnect
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}

final wsServiceProvider = Provider<WebSocketService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return WebSocketService(storage);
});
