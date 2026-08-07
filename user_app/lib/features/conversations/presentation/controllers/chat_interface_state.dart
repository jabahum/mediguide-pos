// chat_interface_state.dart

import 'package:user_app/features/conversations/data/models/message.dart';

final class ChatInterfaceState {
  const ChatInterfaceState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.isTyping = false,
    this.conversationId = '',
    this.errorMessage,
  });

  final List<Message> messages;
  final bool isLoading;
  final bool isConnected;
  final bool isTyping;
  final String conversationId;
  final String? errorMessage;

  ChatInterfaceState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isConnected,
    bool? isTyping,
    String? conversationId,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ChatInterfaceState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      isTyping: isTyping ?? this.isTyping,
      conversationId: conversationId ?? this.conversationId,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
