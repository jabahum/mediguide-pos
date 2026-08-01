import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../utils/common.dart';

class ChatInterfaceController extends GetxController {
  ConversationRepository get _repository =>
      ConversationRepository(BackendApiService.to);
  Timer? _pollTimer;
  // Reactive variables (public, following project guidelines)
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isConnected = false.obs;
  final RxString conversationId = ''.obs;
  User? otherUser;
  final RxBool isTyping = false.obs;

  // Scroll controller for message list
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();

    // Get User object from arguments
    final args = Get.arguments;
    if (args is User) {
      otherUser = args;
    }

    // Find or create conversation with the user
    if (otherUser != null) {
      findOrCreateConversation();
    }
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  /// Find existing conversation or create new one
  Future<void> findOrCreateConversation() async {
    final user = otherUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final conversation = await _repository.findOrCreate(user.id);
      conversationId.value = conversation.id;
      await loadMessages();
      subscribeToMessages();
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Failed to load conversation',
        description: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load messages for current conversation
  Future<void> loadMessages() async {
    if (conversationId.value.isEmpty) return;

    isLoading.value = true;
    try {
      final result = await _repository.messages(conversationId.value);

      messages.clear();
      for (final record in result.items) {
        try {
          final message = Message.fromRecord(record);
          messages.add(message);
        } catch (e) {
          debugPrint('Error creating Message from record: $e');
          debugPrint('Record data: ${record.data}');
        }
      }

      // Scroll to bottom after loading messages
      _scrollToBottom();
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Failed to load messages',
        description: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Send a new message
  Future<void> sendMessage(String content, MessageType type) async {
    if (conversationId.value.isEmpty || content.trim().isEmpty) return;

    try {
      final record = await _repository.send(
        conversationId.value,
        content: content.trim(),
        messageType: type.name,
      );
      messages.add(Message.fromRecord(record));

      // Scroll to bottom after sending message
      _scrollToBottom();
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Failed to send message',
        description: e.toString(),
      );
    }
  }

  /// Send text message (called from UI)
  void sendTextMessage(String content) {
    sendMessage(content, MessageType.text);
  }

  /// Poll for message updates. The backend does not expose realtime transport.
  void subscribeToMessages() {
    if (conversationId.value.isEmpty) return;
    isConnected.value = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadMessages();
    });
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      final currentUserId = AuthService.to.currentUser.value?.id;
      if (currentUserId == null) return;

      final message = messages.firstWhereOrNull((m) => m.id == messageId);
      if (message == null) return;

      final record = await _repository.markRead(
        conversationId.value,
        messageId,
        DateTime.now(),
      );
      final index = messages.indexWhere((item) => item.id == messageId);
      if (index >= 0) messages[index] = Message.fromRecord(record);
    } catch (e) {
      // Silently handle read status errors
    }
  }

  /// Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      final currentUserId = AuthService.to.currentUser.value?.id;
      if (currentUserId == null) return;

      final message = messages.firstWhereOrNull((m) => m.id == messageId);
      if (message == null) return;

      if (!message.hasUserReacted(currentUserId, emoji)) {
        final record = await _repository.react(
          conversationId.value,
          messageId,
          emoji,
          active: true,
        );
        final index = messages.indexWhere((item) => item.id == messageId);
        if (index >= 0) messages[index] = Message.fromRecord(record);
      }
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Failed to add reaction',
        description: e.toString(),
      );
    }
  }

  /// Reply to a message
  Future<void> replyToMessage(String replyToId, String content) async {
    if (conversationId.value.isEmpty || content.trim().isEmpty) return;

    try {
      final record = await _repository.send(
        conversationId.value,
        content: content.trim(),
        messageType: MessageType.text.name,
        replyToId: replyToId,
      );
      messages.add(Message.fromRecord(record));
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Failed to send reply',
        description: e.toString(),
      );
    }
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }
}
