import '../../../../core/network/api_client.dart';
import '../../../domain/models/chat.dart';
import '../../../domain/models/message.dart';

class ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSource(this.apiClient);

  Future<Chat> createChat(String userId1, String userId2) async {
    try {
      final response = await apiClient.post('/chats', data: {
        'user_id1': userId1,
        'user_id2': userId2,
      });
      return Chat.fromJson(response.data['chat'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Future<Chat> getChat(String chatId) async {
    try {
      final response = await apiClient.get('/chats/$chatId');
      return Chat.fromJson(response.data['chat'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final response = await apiClient.get('/chats/user/$userId');
      final List<dynamic> data = response.data['chats'] ?? response.data;
      return data.map((json) => Chat.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user chats: $e');
    }
  }

  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    try {
      final response = await apiClient.post('/chats/$chatId/messages', data: {
        'sender_id': senderId,
        'content': content,
      });
      return Message.fromJson(response.data['message'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<List<Message>> getChatMessages(String chatId, {int? limit, String? beforeMessageId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (beforeMessageId != null) queryParams['before_message_id'] = beforeMessageId;
      
      final response = await apiClient.get('/chats/$chatId/messages', queryParameters: queryParams);
      final List<dynamic> data = response.data['messages'] ?? response.data;
      return data.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get chat messages: $e');
    }
  }

  Future<int> markMessagesAsRead(String chatId, String userId) async {
    try {
      final response = await apiClient.put('/chats/$chatId/messages/read', queryParameters: {'user_id': userId});
      return response.data['marked_count'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }
}

