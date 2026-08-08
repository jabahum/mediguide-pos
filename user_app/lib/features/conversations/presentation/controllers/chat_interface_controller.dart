// chat_interface_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/conversations/data/models/message.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_interface_state.dart';

part 'chat_interface_controller.g.dart';

@riverpod
class ChatInterfaceController extends _$ChatInterfaceController {
  Timer? _pollTimer;
  bool _refreshing = false;

  ConversationRepository get _repository =>
      ref.read(conversationRepositoryProvider);

  String? get _currentUserId =>
      ref.read(authControllerProvider).valueOrNull?.user?.id;

  String get currentUserId => _currentUserId ?? '';

  @override
  ChatInterfaceState build(User otherUser) {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    Future.microtask(findOrCreateConversation);

    return const ChatInterfaceState();
  }

  // ======================================================
  // INITIALIZE
  // ======================================================

  Future<void> findOrCreateConversation() async {
    if (state.isLoading || state.conversationId.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final conversation = await _repository.findOrCreate(otherUser.id);

      state = state.copyWith(conversationId: conversation.id);

      await loadMessages(showLoading: false);

      startPolling();
    } catch (error) {
      _handleError(error);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ======================================================
  // MESSAGES
  // ======================================================

  Future<void> loadMessages({bool showLoading = true}) async {
    final conversationId = state.conversationId;

    if (conversationId.isEmpty || _refreshing) {
      return;
    }

    _refreshing = true;

    if (showLoading && state.messages.isEmpty) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final result = await _repository.messages(conversationId);

      final loaded = <Message>[];

      for (final record in result.items) {
        try {
          loaded.add(record);
        } catch (error) {
          debugPrint('Error creating Message from record: $error');
        }
      }

      state = state.copyWith(
        messages: List<Message>.unmodifiable(loaded),
        clearErrorMessage: true,
      );
    } catch (error) {
      _handleError(error);
    } finally {
      _refreshing = false;

      if (showLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<bool> sendMessage(String content, MessageType type) async {
    final trimmed = content.trim();
    final conversationId = state.conversationId;

    if (conversationId.isEmpty || trimmed.isEmpty) {
      return false;
    }

    try {
      final record = await _repository.send(
        conversationId,
        content: trimmed,
        messageType: type.name,
      );

      state = state.copyWith(
        messages: List<Message>.unmodifiable([...state.messages, record]),
      );

      return true;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  Future<bool> sendTextMessage(String content) {
    return sendMessage(content, MessageType.text);
  }

  Future<bool> replyToMessage(String replyToId, String content) async {
    final trimmed = content.trim();
    final conversationId = state.conversationId;

    if (conversationId.isEmpty || trimmed.isEmpty) {
      return false;
    }

    try {
      final record = await _repository.send(
        conversationId,
        content: trimmed,
        messageType: MessageType.text.name,
        replyToId: replyToId,
      );

      state = state.copyWith(
        messages: List<Message>.unmodifiable([...state.messages, record]),
      );

      return true;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  // ======================================================
  // POLLING
  // ======================================================

  void startPolling() {
    if (state.conversationId.isEmpty) {
      return;
    }

    _pollTimer?.cancel();

    state = state.copyWith(isConnected: true);

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(loadMessages(showLoading: false));
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;

    state = state.copyWith(isConnected: false);
  }

  // ======================================================
  // READ RECEIPTS
  // ======================================================

  Future<void> markAsRead(String messageId) async {
    final userId = _currentUserId;

    final conversationId = state.conversationId;

    if (userId == null || conversationId.isEmpty) {
      return;
    }

    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );

    if (index < 0) {
      return;
    }

    try {
      final record = await _repository.markRead(
        conversationId,
        messageId,
        DateTime.now(),
      );

      final updated = [...state.messages];

      updated[index] = record;

      state = state.copyWith(messages: List<Message>.unmodifiable(updated));
    } catch (_) {
      // Read receipts are best effort.
      // Polling will reconcile the server state.
    }
  }

  // ======================================================
  // REACTIONS
  // ======================================================

  Future<void> addReaction(String messageId, String emoji) async {
    final userId = _currentUserId;

    final conversationId = state.conversationId;

    if (userId == null || conversationId.isEmpty) {
      return;
    }

    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );

    if (index < 0) {
      return;
    }

    final message = state.messages[index];

    if (message.hasUserReacted(userId, emoji)) {
      return;
    }

    try {
      final record = await _repository.react(
        conversationId,
        messageId,
        emoji,
        active: true,
      );

      final updated = [...state.messages];

      updated[index] = record;

      state = state.copyWith(messages: List<Message>.unmodifiable(updated));
    } catch (error) {
      _handleError(error);
    }
  }

  // ======================================================
  // TYPING STATE
  // ======================================================

  void setTyping(bool value) {
    state = state.copyWith(isTyping: value);
  }

  // ======================================================
  // REFRESH
  // ======================================================

  Future<void> refresh() {
    return loadMessages(showLoading: false);
  }

  // ======================================================
  // ERROR
  // ======================================================

  void _handleError(Object error) {
    final message = error.toString();

    state = state.copyWith(errorMessage: message);

    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }
}
