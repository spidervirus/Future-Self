import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/api/services/chat_service.dart';
import '../../../core/api/services/websocket_service.dart';
import '../../../core/api/models/chat_models.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChat extends ChatEvent {}

class ConnectWebSocket extends ChatEvent {}

class DisconnectWebSocket extends ChatEvent {}

class SendMessage extends ChatEvent {
  final String content;
  final String? conversationId;

  const SendMessage({
    required this.content,
    this.conversationId,
  });

  @override
  List<Object?> get props => [content, conversationId];
}

class SendMessageViaWebSocket extends ChatEvent {
  final String content;
  final String? conversationId;

  const SendMessageViaWebSocket({
    required this.content,
    this.conversationId,
  });

  @override
  List<Object?> get props => [content, conversationId];
}

class StartTyping extends ChatEvent {
  final String? conversationId;

  const StartTyping({this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class StopTyping extends ChatEvent {
  final String? conversationId;

  const StopTyping({this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class LoadConversations extends ChatEvent {}

class LoadConversationDetail extends ChatEvent {
  final String conversationId;

  const LoadConversationDetail(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class WebSocketMessageReceived extends ChatEvent {
  final WebSocketResponse response;

  const WebSocketMessageReceived(this.response);

  @override
  List<Object?> get props => [response];
}

class WebSocketConnectionStateChanged extends ChatEvent {
  final WebSocketConnectionState state;

  const WebSocketConnectionStateChanged(this.state);

  @override
  List<Object?> get props => [state];
}

class TypingIndicatorChanged extends ChatEvent {
  final String indicator;

  const TypingIndicatorChanged(this.indicator);

  @override
  List<Object?> get props => [indicator];
}

class WebSocketErrorReceived extends ChatEvent {
  final String error;

  const WebSocketErrorReceived(this.error);

  @override
  List<Object?> get props => [error];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String? currentConversationId;
  final WebSocketConnectionState connectionState;
  final String? typingIndicator;
  final bool isAiThinking;

  const ChatLoaded({
    required this.messages,
    this.currentConversationId,
    this.connectionState = WebSocketConnectionState.disconnected,
    this.typingIndicator,
    this.isAiThinking = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    String? currentConversationId,
    WebSocketConnectionState? connectionState,
    String? typingIndicator,
    bool? isAiThinking,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      connectionState: connectionState ?? this.connectionState,
      typingIndicator: typingIndicator,
      isAiThinking: isAiThinking ?? this.isAiThinking,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        currentConversationId,
        connectionState,
        typingIndicator,
        isAiThinking,
      ];
}

class ConversationsLoaded extends ChatState {
  final List<ConversationSummary> conversations;

  const ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class ConversationDetailLoaded extends ChatState {
  final ConversationDetail conversation;
  final WebSocketConnectionState connectionState;
  final String? typingIndicator;

  const ConversationDetailLoaded({
    required this.conversation,
    this.connectionState = WebSocketConnectionState.disconnected,
    this.typingIndicator,
  });

  ConversationDetailLoaded copyWith({
    ConversationDetail? conversation,
    WebSocketConnectionState? connectionState,
    String? typingIndicator,
  }) {
    return ConversationDetailLoaded(
      conversation: conversation ?? this.conversation,
      connectionState: connectionState ?? this.connectionState,
      typingIndicator: typingIndicator,
    );
  }

  @override
  List<Object?> get props => [conversation, connectionState, typingIndicator];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;
  final WebSocketService _webSocketService;

  StreamSubscription<WebSocketResponse>? _messageSubscription;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;
  StreamSubscription<String>? _typingSubscription;
  StreamSubscription<String>? _errorSubscription;
  Timer? _typingTimer;

  ChatBloc({
    required ChatService chatService,
    required WebSocketService webSocketService,
  })  : _chatService = chatService,
        _webSocketService = webSocketService,
        super(ChatInitial()) {
    on<InitializeChat>(_onInitializeChat);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<SendMessage>(_onSendMessage);
    on<SendMessageViaWebSocket>(_onSendMessageViaWebSocket);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<LoadConversations>(_onLoadConversations);
    on<LoadConversationDetail>(_onLoadConversationDetail);
    on<WebSocketMessageReceived>(_onWebSocketMessageReceived);
    on<WebSocketConnectionStateChanged>(_onWebSocketConnectionStateChanged);
    on<TypingIndicatorChanged>(_onTypingIndicatorChanged);
    on<WebSocketErrorReceived>(_onWebSocketErrorReceived);
  }

  Future<void> _onInitializeChat(
      InitializeChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      emit(const ChatLoaded(messages: []));
      add(ConnectWebSocket());
    } catch (e) {
      emit(ChatError('Failed to initialize chat: ${e.toString()}'));
    }
  }

  Future<void> _onConnectWebSocket(
      ConnectWebSocket event, Emitter<ChatState> emit) async {
    try {
      await _webSocketService.connect();
      _setupWebSocketListeners();
    } catch (e) {
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(
          connectionState: WebSocketConnectionState.error,
        ));
      }
    }
  }

  Future<void> _onDisconnectWebSocket(
      DisconnectWebSocket event, Emitter<ChatState> emit) async {
    _webSocketService.disconnect();
    _clearSubscriptions();

    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(
        connectionState: WebSocketConnectionState.disconnected,
      ));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    try {
      final request = SendMessageRequest(
        content: event.content,
        conversationId: event.conversationId,
      );

      final response = await _chatService.sendMessage(request);

      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final updatedMessages = [
          ...currentState.messages,
          response.userMessage,
          response.aiMessage,
        ];

        emit(currentState.copyWith(
          messages: updatedMessages,
          currentConversationId: response.conversationId,
        ));
      }
    } catch (e) {
      emit(ChatError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> _onSendMessageViaWebSocket(
      SendMessageViaWebSocket event, Emitter<ChatState> emit) async {
    if (!_webSocketService.isConnected) {
      add(SendMessage(
          content: event.content, conversationId: event.conversationId));
      return;
    }

    try {
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isAiThinking: true));
      }

      _webSocketService.sendChatMessage(
        event.content,
        conversationId: event.conversationId,
      );
    } catch (e) {
      emit(ChatError('Failed to send WebSocket message: ${e.toString()}'));
    }
  }

  Future<void> _onStartTyping(
      StartTyping event, Emitter<ChatState> emit) async {
    if (_webSocketService.isConnected) {
      _webSocketService.sendTypingIndicator(
          conversationId: event.conversationId);
    }

    // Auto-stop typing after 3 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      add(StopTyping(conversationId: event.conversationId));
    });
  }

  Future<void> _onStopTyping(StopTyping event, Emitter<ChatState> emit) async {
    _typingTimer?.cancel();
    if (_webSocketService.isConnected) {
      _webSocketService.sendStopTyping(conversationId: event.conversationId);
    }
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final response = await _chatService.getConversations();
      emit(ConversationsLoaded(response.conversations));
    } catch (e) {
      emit(ChatError('Failed to load conversations: ${e.toString()}'));
    }
  }

  Future<void> _onLoadConversationDetail(
      LoadConversationDetail event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final conversation =
          await _chatService.getConversationDetail(event.conversationId);
      emit(ConversationDetailLoaded(conversation: conversation));
    } catch (e) {
      emit(ChatError('Failed to load conversation: ${e.toString()}'));
    }
  }

  Future<void> _onWebSocketMessageReceived(
      WebSocketMessageReceived event, Emitter<ChatState> emit) async {
    final response = event.response;

    switch (response.type) {
      case 'user_message':
        _handleUserMessage(response, emit);
        break;
      case 'ai_message':
        _handleAiMessage(response, emit);
        break;
    }
  }

  void _handleUserMessage(WebSocketResponse response, Emitter<ChatState> emit) {
    if (state is ChatLoaded && response.content != null) {
      final currentState = state as ChatLoaded;
      final userMessage = ChatMessage(
        id: response.messageId ?? '',
        conversationId: response.conversationId ?? '',
        role: 'user',
        content: response.content!,
        messageType: 'text',
        metadata: response.metadata,
        tokenCount: null,
        createdAt: response.timestamp,
      );

      final updatedMessages = [...currentState.messages, userMessage];
      emit(currentState.copyWith(
        messages: updatedMessages,
        currentConversationId: response.conversationId,
      ));
    }
  }

  void _handleAiMessage(WebSocketResponse response, Emitter<ChatState> emit) {
    if (state is ChatLoaded && response.content != null) {
      final currentState = state as ChatLoaded;
      final aiMessage = ChatMessage(
        id: response.messageId ?? '',
        conversationId: response.conversationId ?? '',
        role: 'assistant',
        content: response.content!,
        messageType: 'text',
        metadata: response.metadata,
        tokenCount: response.metadata?['token_count']?.toString(),
        createdAt: response.timestamp,
      );

      final updatedMessages = [...currentState.messages, aiMessage];
      emit(currentState.copyWith(
        messages: updatedMessages,
        currentConversationId: response.conversationId,
        isAiThinking: false,
      ));
    }
  }

  Future<void> _onWebSocketConnectionStateChanged(
      WebSocketConnectionStateChanged event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(connectionState: event.state));
    } else if (state is ConversationDetailLoaded) {
      emit((state as ConversationDetailLoaded)
          .copyWith(connectionState: event.state));
    }
  }

  Future<void> _onTypingIndicatorChanged(
      TypingIndicatorChanged event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(
          typingIndicator: event.indicator.isEmpty ? null : event.indicator));
    } else if (state is ConversationDetailLoaded) {
      emit((state as ConversationDetailLoaded).copyWith(
          typingIndicator: event.indicator.isEmpty ? null : event.indicator));
    }
  }

  Future<void> _onWebSocketErrorReceived(
      WebSocketErrorReceived event, Emitter<ChatState> emit) async {
    emit(ChatError('WebSocket error: ${event.error}'));
  }

  void _setupWebSocketListeners() {
    _messageSubscription = _webSocketService.messages.listen(
      (response) => add(WebSocketMessageReceived(response)),
    );

    _connectionSubscription = _webSocketService.connectionState.listen(
      (state) => add(WebSocketConnectionStateChanged(state)),
    );

    _typingSubscription = _webSocketService.typingIndicators.listen(
      (indicator) => add(TypingIndicatorChanged(indicator)),
    );

    _errorSubscription = _webSocketService.errors.listen(
      (error) => add(WebSocketErrorReceived(error)),
    );
  }

  void _clearSubscriptions() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _typingSubscription?.cancel();
    _errorSubscription?.cancel();
    _typingTimer?.cancel();

    _messageSubscription = null;
    _connectionSubscription = null;
    _typingSubscription = null;
    _errorSubscription = null;
    _typingTimer = null;
  }

  @override
  Future<void> close() {
    _clearSubscriptions();
    _webSocketService.dispose();
    return super.close();
  }
}
