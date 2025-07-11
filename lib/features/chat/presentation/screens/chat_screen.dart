import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/cosmic_dream_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/api/services/websocket_service.dart';
import '../../bloc/chat_bloc.dart';
import '../../../../core/api/models/chat_models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatBloc? _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = sl<ChatBloc>();
    _chatBloc!.add(InitializeChat());

    // Listen to text changes for typing indicators
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty) {
      _chatBloc?.add(const StartTyping());
    } else {
      _chatBloc?.add(const StopTyping());
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc?.close();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final currentState = _chatBloc?.state;
    String? conversationId;

    if (currentState is ChatLoaded) {
      conversationId = currentState.currentConversationId;
    }

    // Use WebSocket if connected, otherwise fallback to HTTP
    if (currentState is ChatLoaded &&
        currentState.connectionState == WebSocketConnectionState.connected) {
      _chatBloc?.add(SendMessageViaWebSocket(
        content: content,
        conversationId: conversationId,
      ));
    } else {
      _chatBloc?.add(SendMessage(
        content: content,
        conversationId: conversationId,
      ));
    }

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc!,
      child: Scaffold(
        backgroundColor: CosmicDreamTheme.background,
        appBar: AppBar(
          title: const Text('Chat with Future Self'),
          backgroundColor: CosmicDreamTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoaded) {
                  return _buildConnectionIndicator(state.connectionState);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded && state.messages.isNotEmpty) {
              _scrollToBottom();
            }
            if (state is ChatError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: CosmicDreamTheme.accent,
                        ),
                      );
                    }

                    if (state is ChatLoaded) {
                      return _buildChatContent(state);
                    }

                    if (state is ChatError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Something went wrong',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                _chatBloc?.add(InitializeChat());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    return const Center(
                      child: Text(
                        'Start a conversation with your Future Self',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator(WebSocketConnectionState connectionState) {
    Color color;
    IconData icon;
    String tooltip;

    switch (connectionState) {
      case WebSocketConnectionState.connected:
        color = Colors.green;
        icon = PhosphorIcons.wifiHigh();
        tooltip = 'Real-time connected';
        break;
      case WebSocketConnectionState.connecting:
        color = Colors.orange;
        icon = PhosphorIcons.circleNotch();
        tooltip = 'Connecting...';
        break;
      case WebSocketConnectionState.reconnecting:
        color = Colors.orange;
        icon = PhosphorIcons.arrowsClockwise();
        tooltip = 'Reconnecting...';
        break;
      case WebSocketConnectionState.disconnected:
        color = Colors.grey;
        icon = PhosphorIcons.wifiSlash();
        tooltip = 'Offline mode';
        break;
      case WebSocketConnectionState.error:
        color = Colors.red;
        icon = PhosphorIcons.warning();
        tooltip = 'Connection error';
        break;
    }

    Widget iconWidget = PhosphorIcon(
      icon,
      color: color,
      size: 20,
    );

    // Add animations for certain states
    if (connectionState == WebSocketConnectionState.connecting ||
        connectionState == WebSocketConnectionState.reconnecting) {
      iconWidget = iconWidget
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 2.seconds);
    } else if (connectionState == WebSocketConnectionState.connected) {
      iconWidget = iconWidget
          .animate()
          .fadeIn(duration: 500.ms)
          .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0));
    }

    return Tooltip(
      message: tooltip,
      child: iconWidget,
    );
  }

  Widget _buildChatContent(ChatLoaded state) {
    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
        ),
        if (state.typingIndicator != null)
          _buildTypingIndicator(state.typingIndicator!),
        if (state.isAiThinking) _buildAiThinkingIndicator(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  CosmicDreamTheme.primary.withOpacity(0.3),
                  CosmicDreamTheme.accent.withOpacity(0.3),
                ],
              ),
            ),
            child: PhosphorIcon(
              PhosphorIcons.brain(),
              size: 60,
              color: Colors.white,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                  duration: 3.seconds, color: Colors.white.withOpacity(0.3))
              .then()
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 1.seconds,
              )
              .then()
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.0, 1.0),
                duration: 1.seconds,
              ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Your Future Self',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to get personalized guidance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 32),
          ...[
            'What should I focus on today?',
            'Help me with goal setting',
            'I need motivation'
          ].asMap().entries.map(
            (entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () {
                    _messageController.text = suggestion;
                    _sendMessage();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CosmicDreamTheme.accent),
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(color: CosmicDreamTheme.accent),
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 700 + (index * 150)))
                    .slideX(begin: 0.3, end: 0),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final isAssistant = message.role == 'assistant';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: CosmicDreamTheme.accent,
              child: PhosphorIcon(
                PhosphorIcons.brain(),
                size: 18,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? CosmicDreamTheme.primary : Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(
                  begin: isUser ? 0.3 : -0.3,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: CosmicDreamTheme.primary,
              child: PhosphorIcon(
                PhosphorIcons.user(),
                size: 18,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(String indicator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: CosmicDreamTheme.accent,
            child: PhosphorIcon(
              PhosphorIcons.brain(),
              size: 14,
              color: Colors.white,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds),
          const SizedBox(width: 8),
          Text(
            indicator,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1.seconds)
              .then()
              .fadeOut(duration: 1.seconds),
        ],
      ),
    );
  }

  Widget _buildAiThinkingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: CosmicDreamTheme.accent,
            child: PhosphorIcon(
              PhosphorIcons.brain(),
              size: 14,
              color: Colors.white,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds),
          const SizedBox(width: 8),
          const Text(
            'Future Self is thinking...',
            style: TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1.seconds)
              .then()
              .fadeOut(duration: 1.seconds),
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CosmicDreamTheme.accent,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1.seconds),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        const BorderSide(color: CosmicDreamTheme.accent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        const BorderSide(color: CosmicDreamTheme.accent),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: CosmicDreamTheme.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: PhosphorIcon(
                  PhosphorIcons.paperPlaneTilt(),
                  color: Colors.white,
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: 200.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1.0, 1.0),
                  duration: 200.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ),
      ),
    );
  }
}
