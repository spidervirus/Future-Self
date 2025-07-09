import 'package:dio/dio.dart';
import '../api_client.dart';
import '../models/chat_models.dart';
import '../models/auth_models.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<ChatResponse> sendMessage(SendMessageRequest request) async {
    try {
      final response = await _apiClient.post(
        '/chat/send',
        data: request.toJson(),
      );

      return ChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to send message: ${e.toString()}');
    }
  }

  Future<ConversationListResponse> getConversations({
    int limit = 20,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          'include_archived': includeArchived,
        },
      );

      return ConversationListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to get conversations: ${e.toString()}');
    }
  }

  Future<ConversationDetail> getConversationDetail(
      String conversationId) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId',
      );

      return ConversationDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to get conversation: ${e.toString()}');
    }
  }

  Future<ConversationSummary> createConversation({
    String? title,
    String? initialMessage,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (initialMessage != null) data['initial_message'] = initialMessage;

      final response = await _apiClient.post(
        '/chat/conversations',
        data: data,
      );

      return ConversationSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to create conversation: ${e.toString()}');
    }
  }

  Future<ConversationSummary> updateConversation(
    String conversationId, {
    String? title,
    bool? isArchived,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (isArchived != null) data['is_archived'] = isArchived;

      final response = await _apiClient.put(
        '/chat/conversations/$conversationId',
        data: data,
      );

      return ConversationSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to update conversation: ${e.toString()}');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _apiClient.delete('/chat/conversations/$conversationId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to delete conversation: ${e.toString()}');
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await _apiClient.delete('/chat/history');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to clear chat history: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getConversationStarter() async {
    try {
      final response = await _apiClient.get('/chat/starter');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(
          message: 'Failed to get conversation starter: ${e.toString()}');
    }
  }

  Future<DailyMessage> getTodaysDailyMessage() async {
    try {
      final response = await _apiClient.get('/chat/daily-message');
      return DailyMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to get daily message: ${e.toString()}');
    }
  }

  Future<void> markDailyMessageAsRead(String messageId) async {
    try {
      await _apiClient.post('/chat/daily-message/mark-read', data: {
        'message_id': messageId,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(
          message: 'Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> checkOllamaHealth() async {
    try {
      final response = await _apiClient.get('/chat/health/ollama');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to check Ollama health: ${e.toString()}');
    }
  }

  ApiError _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ApiError.fromJson(data);
      }
      return ApiError(
        message: data.toString(),
        statusCode: e.response!.statusCode,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiError(message: 'Connection timeout');
      case DioExceptionType.receiveTimeout:
        return const ApiError(message: 'Receive timeout');
      case DioExceptionType.sendTimeout:
        return const ApiError(message: 'Send timeout');
      case DioExceptionType.connectionError:
        return const ApiError(
            message:
                'Connection error. Please check your internet connection.');
      default:
        return ApiError(message: 'Network error: ${e.message}');
    }
  }
}
