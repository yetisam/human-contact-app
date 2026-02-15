import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/chat_message.dart';

class ChatService {
  final ApiClient _api;

  ChatService(this._api);

  /// Get chat messages and connection info
  Future<ChatLoadResponse> getMessages(String connectionId, {String? before}) async {
    try {
      final params = <String, dynamic>{'limit': 50};
      if (before != null) params['before'] = before;

      final response = await _api.get(
        '/chat/$connectionId/messages',
        queryParameters: params,
      );
      return ChatLoadResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Send message via HTTP (fallback when WS not connected)
  Future<ChatMessage> sendMessage(String connectionId, String content) async {
    try {
      final response = await _api.post(
        '/chat/$connectionId/messages',
        data: {'content': content},
      );
      return ChatMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(apiClientProvider));
});
