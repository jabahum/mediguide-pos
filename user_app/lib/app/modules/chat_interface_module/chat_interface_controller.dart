import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../utils/common.dart';

class ChatInterfaceController extends GetxController {
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
    // Clean up real-time subscriptions
    if (conversationId.value.isNotEmpty) {
      BackendApiService.to.unsubscribeFromCollection(
        collectionName: 'messages',
      );
    }
    scrollController.dispose();
    super.onClose();
  }

  /// Find existing conversation or create new one
  Future<void> findOrCreateConversation() async {
    final user = otherUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final currentUserId = AuthService.to.currentUser.value?.id;
      if (currentUserId == null) return;

      // Try to find existing conversation
      final filter =
          '(participant1 = "$currentUserId" && participant2 = "${user.id}") || (participant1 = "${user.id}" && participant2 = "$currentUserId")';

      final existingConversations = await BackendApiService.to.getResourceList(
        collectionName: 'conversations',
        filter: filter,
      );

      if (existingConversations.items.isNotEmpty) {
        // Use existing conversation
        conversationId.value = existingConversations.items.first.id;
        loadMessages();
        subscribeToMessages();
      } else {
        // Create new conversation
        final newConversation = await BackendApiService.to.createResource(
          collectionName: 'conversations',
          data: Conversation.forCreate(
            participant1: currentUserId,
            participant2: user.id,
          ),
        );

        conversationId.value = newConversation.id;
        subscribeToMessages();
      }
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
      final result = await BackendApiService.to.getResourceList(
        collectionName: 'messages',
        filter: 'conversation = "${conversationId.value}"',
        sort: 'created',
        expand: 'sender,reply_to',
      );

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

    final currentUserId = AuthService.to.currentUser.value?.id;
    if (currentUserId == null) return;

    try {
      await BackendApiService.to.createResource(
        collectionName: 'messages',
        data: Message.forCreate(
          conversation: conversationId.value,
          sender: currentUserId,
          content: content.trim(),
          messageType: type,
        ),
      );

      // Update conversation last activity
      await BackendApiService.to.updateResource(
        collectionName: 'conversations',
        recordId: conversationId.value,
        data: Conversation.forUpdate(lastActivity: DateTime.now()),
      );

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

  /// Subscribe to real-time message updates
  void subscribeToMessages() {
    if (conversationId.value.isEmpty) return;

    isConnected.value = true;

    BackendApiService.to.subscribeToCollection('messages', (e) {
      try {
        final record = e.record;
        if (record == null) return;

        final message = Message.fromRecord(record);

        switch (e.action) {
          case 'create':
            messages.add(message);
            // Scroll to bottom when new message arrives
            _scrollToBottom();
            break;
          case 'update':
            final index = messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              messages[index] = message;
            }
            break;
          case 'delete':
            messages.removeWhere((m) => m.id == message.id);
            break;
        }
      } catch (e) {
        // Silently handle real-time message errors to avoid disrupting chat flow
      }
    }, filter: 'conversation = "${conversationId.value}"');
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      final currentUserId = AuthService.to.currentUser.value?.id;
      if (currentUserId == null) return;

      final message = messages.firstWhereOrNull((m) => m.id == messageId);
      if (message == null) return;

      final updatedReadBy = Map<String, dynamic>.from(message.readBy);
      updatedReadBy[currentUserId] = DateTime.now().toIso8601String();

      await BackendApiService.to.updateResource(
        collectionName: 'messages',
        recordId: messageId,
        data: Message.forUpdate(readBy: updatedReadBy),
      );
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

      final updatedReactions = Map<String, dynamic>.from(message.reactions);
      final userIds = List<String>.from(updatedReactions[emoji] ?? []);

      if (!userIds.contains(currentUserId)) {
        userIds.add(currentUserId);
        updatedReactions[emoji] = userIds;

        await BackendApiService.to.updateResource(
          collectionName: 'messages',
          recordId: messageId,
          data: Message.forUpdate(reactions: updatedReactions),
        );
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

    final currentUserId = AuthService.to.currentUser.value?.id;
    if (currentUserId == null) return;

    try {
      await BackendApiService.to.createResource(
        collectionName: 'messages',
        data: Message.forCreate(
          conversation: conversationId.value,
          sender: currentUserId,
          content: content.trim(),
          messageType: MessageType.text,
          replyTo: replyToId,
        ),
      );
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
