import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';
import 'auth_service.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketMessage {
  final String type;
  final String? content;
  final String? conversationId;
  final Map<String, dynamic>? metadata;

  WebSocketMessage({
    required this.type,
    this.content,
    this.conversationId,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'conversation_id': conversationId,
        'metadata': metadata,
      };
}

class WebSocketResponse {
  final String type;
  final String? content;
  final String? messageId;
  final String? conversationId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  WebSocketResponse({
    required this.type,
    this.content,
    this.messageId,
    this.conversationId,
    required this.timestamp,
    this.metadata,
  });

  factory WebSocketResponse.fromJson(Map<String, dynamic> json) {
    return WebSocketResponse(
      type: json['type'] ?? '',
      content: json['content'],
      messageId: json['message_id'],
      conversationId: json['conversation_id'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'],
    );
  }
}

class WebSocketService {
  static const String _baseUrl = 'ws://localhost:8000';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  // State management
  final StreamController<WebSocketConnectionState> _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final StreamController<WebSocketResponse> _messageController =
      StreamController<WebSocketResponse>.broadcast();
  final StreamController<String> _typingController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  WebSocketConnectionState _currentState =
      WebSocketConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  // Streams
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<WebSocketResponse> get messages => _messageController.stream;
  Stream<String> get typingIndicators => _typingController.stream;
  Stream<String> get errors => _errorController.stream;

  WebSocketConnectionState get currentState => _currentState;
  bool get isConnected => _currentState == WebSocketConnectionState.connected;

  Future<void> connect() async {
    if (_currentState == WebSocketConnectionState.connecting ||
        _currentState == WebSocketConnectionState.connected) {
      return;
    }

    try {
      _updateConnectionState(WebSocketConnectionState.connecting);

      // Get authentication token
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create WebSocket connection with auth header
      final uri = Uri.parse('$_baseUrl/api/v1/chat/ws');

      // For web, we can't set custom headers in WebSocket constructor
      // We'll need to handle auth differently for web vs mobile
      if (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isLinux ||
          Platform.isWindows) {
        _channel = IOWebSocketChannel.connect(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      } else {
        // For web, we'll send auth in the first message
        _channel = WebSocketChannel.connect(uri);
      }

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Send authentication for web platforms
      if (!Platform.isAndroid &&
          !Platform.isIOS &&
          !Platform.isMacOS &&
          !Platform.isLinux &&
          !Platform.isWindows) {
        final authMessage = WebSocketMessage(
          type: 'auth',
          metadata: {'token': token},
        );
        _sendMessage(authMessage);
      }

      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();
    } catch (e) {
      _updateConnectionState(WebSocketConnectionState.error);
      _errorController.add('Connection failed: ${e.toString()}');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> json = jsonDecode(data);
      final response = WebSocketResponse.fromJson(json);

      switch (response.type) {
        case 'connected':
          _updateConnectionState(WebSocketConnectionState.connected);
          break;
        case 'user_message':
        case 'ai_message':
          _messageController.add(response);
          break;
        case 'ai_typing':
          _typingController.add('AI is typing...');
          break;
        case 'user_typing':
          _typingController.add('User is typing...');
          break;
        case 'user_stopped_typing':
          _typingController.add('');
          break;
        case 'error':
          _errorController.add(response.content ?? 'Unknown error');
          break;
        default:
          _messageController.add(response);
      }
    } catch (e) {
      _errorController.add('Failed to parse message: ${e.toString()}');
    }
  }

  void _handleError(error) {
    _updateConnectionState(WebSocketConnectionState.error);
    _errorController.add('WebSocket error: ${error.toString()}');
    _scheduleReconnect();
  }

  void _handleDisconnection() {
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateConnectionState(WebSocketConnectionState.error);
      _errorController.add('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _updateConnectionState(WebSocketConnectionState.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      connect();
    });
  }

  void _updateConnectionState(WebSocketConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (isConnected) {
        final pingMessage = WebSocketMessage(type: 'ping');
        _sendMessage(pingMessage);
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _sendMessage(WebSocketMessage message) {
    if (_channel != null && isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message.toJson()));
      } catch (e) {
        _errorController.add('Failed to send message: ${e.toString()}');
      }
    }
  }

  // Public methods for sending different types of messages
  void sendChatMessage(String content, {String? conversationId}) {
    final message = WebSocketMessage(
      type: 'message',
      content: content,
      conversationId: conversationId,
    );
    _sendMessage(message);
  }

  void sendTypingIndicator({String? conversationId}) {
    final message = WebSocketMessage(
      type: 'typing',
      conversationId: conversationId,
    );
    _sendMessage(message);
  }

  void sendStopTyping({String? conversationId}) {
    final message = WebSocketMessage(
      type: 'stop_typing',
      conversationId: conversationId,
    );
    _sendMessage(message);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _stopPingTimer();
    _channel?.sink.close();
    _channel = null;
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
    _typingController.close();
    _errorController.close();
  }
}
