import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/conversations/data/models/message.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';

final chatInterfaceControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ChatInterfaceController, User>((ref, otherUser) {
      final controller = ChatInterfaceController(
        ref.watch(conversationRepositoryProvider),
        otherUser: otherUser,
        currentUserId: ref.watch(authControllerProvider).valueOrNull?.user?.id,
      );
      unawaited(controller.initialize());
      return controller;
    });

class ChatInterfaceController extends ChangeNotifier {
  ChatInterfaceController(
    this._repository, {
    required this.otherUser,
    required this.currentUserId,
  });

  final ConversationRepository _repository;
  final User otherUser;
  final String? currentUserId;
  final List<Message> messages = [];

  Timer? _pollTimer;
  bool _disposed = false;
  bool _refreshing = false;
  bool isLoading = false;
  bool isConnected = false;
  bool isTyping = false;
  String conversationId = '';

  Future<void> initialize() => findOrCreateConversation();

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> findOrCreateConversation() async {
    if (isLoading || conversationId.isNotEmpty) return;
    isLoading = true;
    _notify();
    try {
      final conversation = await _repository.findOrCreate(otherUser.id);
      conversationId = conversation.id;
      await loadMessages(showLoading: false);
      startPolling();
    } catch (error) {
      AppMessage.error(AppKeys.navigatorKey.currentContext!, '$error');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> loadMessages({bool showLoading = true}) async {
    if (conversationId.isEmpty || _refreshing) return;
    _refreshing = true;
    if (showLoading && messages.isEmpty) {
      isLoading = true;
      _notify();
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
      messages
        ..clear()
        ..addAll(loaded);
      _notify();
    } catch (error) {
      AppMessage.error(AppKeys.navigatorKey.currentContext!, '$error');
    } finally {
      _refreshing = false;
      if (showLoading) isLoading = false;
      _notify();
    }
  }

  Future<bool> sendMessage(String content, MessageType type) async {
    final trimmed = content.trim();
    if (conversationId.isEmpty || trimmed.isEmpty) return false;
    try {
      final record = await _repository.send(
        conversationId,
        content: trimmed,
        messageType: type.name,
      );
      messages.add(record);
      _notify();
      return true;
    } catch (error) {
      AppMessage.error(AppKeys.navigatorKey.currentContext!, '$error');

      return false;
    }
  }

  Future<bool> sendTextMessage(String content) =>
      sendMessage(content, MessageType.text);

  /// The backend has no realtime transport, so this feature explicitly polls.
  void startPolling() {
    if (conversationId.isEmpty || _disposed) return;
    isConnected = true;
    _notify();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(loadMessages(showLoading: false)),
    );
  }

  Future<void> markAsRead(String messageId) async {
    if (currentUserId == null || conversationId.isEmpty) return;
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index < 0) return;
    try {
      final record = await _repository.markRead(
        conversationId,
        messageId,
        DateTime.now(),
      );
      messages[index] = record;
      _notify();
    } catch (_) {
      // Read receipts are best effort and polling will reconcile their state.
    }
  }

  Future<void> addReaction(String messageId, String emoji) async {
    final userId = currentUserId;
    if (userId == null || conversationId.isEmpty) return;
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index < 0 || messages[index].hasUserReacted(userId, emoji)) return;
    try {
      final record = await _repository.react(
        conversationId,
        messageId,
        emoji,
        active: true,
      );
      messages[index] = record;
      _notify();
    } catch (error) {
      AppMessage.error(AppKeys.navigatorKey.currentContext!, '$error');
    }
  }

  Future<bool> replyToMessage(String replyToId, String content) async {
    final trimmed = content.trim();
    if (conversationId.isEmpty || trimmed.isEmpty) return false;
    try {
      final record = await _repository.send(
        conversationId,
        content: trimmed,
        messageType: MessageType.text.name,
        replyToId: replyToId,
      );
      messages.add(record);
      _notify();
      return true;
    } catch (error) {
      AppMessage.error(AppKeys.navigatorKey.currentContext!, '$error');
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
