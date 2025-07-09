import 'package:equatable/equatable.dart';

// Chat Message
class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final String? tokenCount;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.messageType,
    this.metadata,
    this.tokenCount,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      role: json['role'],
      content: json['content'],
      messageType: json['message_type'],
      metadata: json['metadata'],
      tokenCount: json['token_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'message_type': messageType,
      'metadata': metadata,
      'token_count': tokenCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        role,
        content,
        messageType,
        metadata,
        tokenCount,
        createdAt,
      ];
}

// Chat Response (from send message endpoint)
class ChatResponse extends Equatable {
  final ChatMessage userMessage;
  final ChatMessage aiMessage;
  final String conversationId;
  final bool isNewConversation;

  const ChatResponse({
    required this.userMessage,
    required this.aiMessage,
    required this.conversationId,
    required this.isNewConversation,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      userMessage: ChatMessage.fromJson(json['user_message']),
      aiMessage: ChatMessage.fromJson(json['ai_message']),
      conversationId: json['conversation_id'],
      isNewConversation: json['is_new_conversation'],
    );
  }

  @override
  List<Object?> get props => [
        userMessage,
        aiMessage,
        conversationId,
        isNewConversation,
      ];
}

// Conversation Summary
class ConversationSummary extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final int messageCount;
  final DateTime lastMessageAt;
  final bool isArchived;
  final DateTime createdAt;

  const ConversationSummary({
    required this.id,
    required this.title,
    this.summary,
    required this.messageCount,
    required this.lastMessageAt,
    required this.isArchived,
    required this.createdAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      messageCount: json['message_count'],
      lastMessageAt: DateTime.parse(json['last_message_at']),
      isArchived: json['is_archived'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        messageCount,
        lastMessageAt,
        isArchived,
        createdAt,
      ];
}

// Conversation Detail (with all messages)
class ConversationDetail extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ConversationDetail({
    required this.id,
    required this.title,
    this.summary,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    return ConversationDetail(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      isArchived: json['is_archived'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messages: (json['messages'] as List)
          .map((messageJson) => ChatMessage.fromJson(messageJson))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        isArchived,
        createdAt,
        updatedAt,
        messages,
      ];
}

// Send Message Request
class SendMessageRequest extends Equatable {
  final String content;
  final String? conversationId;
  final String messageType;
  final Map<String, dynamic>? metadata;

  const SendMessageRequest({
    required this.content,
    this.conversationId,
    this.messageType = 'text',
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'conversation_id': conversationId,
      'message_type': messageType,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [content, conversationId, messageType, metadata];
}

// Conversation List Response
class ConversationListResponse extends Equatable {
  final List<ConversationSummary> conversations;
  final int totalCount;
  final bool hasMore;

  const ConversationListResponse({
    required this.conversations,
    required this.totalCount,
    required this.hasMore,
  });

  factory ConversationListResponse.fromJson(Map<String, dynamic> json) {
    return ConversationListResponse(
      conversations: (json['conversations'] as List)
          .map((conv) => ConversationSummary.fromJson(conv))
          .toList(),
      totalCount: json['total_count'],
      hasMore: json['has_more'],
    );
  }

  @override
  List<Object?> get props => [conversations, totalCount, hasMore];
}

// Daily Message
class DailyMessage extends Equatable {
  final String id;
  final String message;
  final String? moodContext;
  final bool isRead;
  final DateTime createdAt;

  const DailyMessage({
    required this.id,
    required this.message,
    this.moodContext,
    required this.isRead,
    required this.createdAt,
  });

  factory DailyMessage.fromJson(Map<String, dynamic> json) {
    return DailyMessage(
      id: json['id'],
      message: json['message'],
      moodContext: json['mood_context'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, message, moodContext, isRead, createdAt];
}
