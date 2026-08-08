import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/conversations/data/models/conversation.dart';
import 'package:user_app/features/conversations/data/models/message.dart';

final conversationLocalRepositoryProvider =
    Provider<ConversationLocalRepository>((ref) {
      return ConversationLocalRepository(ref.watch(localCacheServiceProvider));
    });

class ConversationLocalRepository {
  ConversationLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _conversationType = 'conversation';
  static const String _messageType = 'conversation_message';

  // =========================================================
  // SCOPE
  // =========================================================

  String _scope(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User id is required for conversation cache',
      );
    }

    return 'user:$normalized';
  }

  // =========================================================
  // SAVE CONVERSATION
  // =========================================================

  Future<void> saveConversation({
    required String userId,
    required Conversation conversation,
  }) {
    return _localCacheService.put(
      type: _conversationType,
      id: conversation.id,
      scope: _scope(userId),
      data: conversation.toJson(),
      searchableText: _conversationSearchText(conversation, userId),
      metadata: _conversationMetadata(conversation, userId),
      remoteUpdatedAt: _conversationUpdatedAt(conversation),
    );
  }

  // =========================================================
  // SAVE CONVERSATIONS
  // =========================================================

  Future<void> saveConversations({
    required String userId,
    required Iterable<Conversation> conversations,
  }) async {
    if (conversations.isEmpty) return;

    final scope = _scope(userId);

    await _localCacheService.putMany(
      type: _conversationType,
      scope: scope,
      entities: conversations.map((conversation) {
        return CachedEntityInput(
          id: conversation.id,
          data: conversation.toJson(),
          searchableText: _conversationSearchText(conversation, userId),
          metadata: _conversationMetadata(conversation, userId),
          remoteUpdatedAt: _conversationUpdatedAt(conversation),
        );
      }),
    );
  }

  // =========================================================
  // GET CONVERSATION
  // =========================================================

  Future<Conversation?> getConversation({
    required String userId,
    required String conversationId,
  }) async {
    final id = conversationId.trim();

    if (id.isEmpty) return null;

    final json = await _localCacheService.get(
      type: _conversationType,
      id: id,
      scope: _scope(userId),
    );

    if (json == null) return null;

    try {
      return Conversation.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // LIST CONVERSATIONS
  // =========================================================

  Future<List<Conversation>> getConversations({
    required String userId,
    int page = 1,
    int perPage = 20,
    String search = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 20 : perPage;

    final rows = await _localCacheService.list(
      type: _conversationType,
      scope: _scope(userId),
      search: search.trim(),
      limit: safePerPage,
      offset: (safePage - 1) * safePerPage,
    );

    final conversations = <Conversation>[];

    for (final row in rows) {
      try {
        conversations.add(Conversation.fromJson(row));
      } catch (_) {
        // Ignore malformed cached records.
      }
    }

    return conversations;
  }

  // =========================================================
  // SAVE MESSAGE
  // =========================================================

  Future<void> saveMessage({
    required String userId,
    required String conversationId,
    required Message message,
  }) {
    return _localCacheService.put(
      type: _messageEntityType(conversationId),
      id: message.id,
      scope: _scope(userId),
      data: message.toJson(),
      searchableText: message.content.toLowerCase(),
      metadata: {
        'conversationId': conversationId,
        'sender': message.sender,
        'messageType': message.messageType.name,
        'createdAt': message.createdDate?.toIso8601String(),
      },
      remoteUpdatedAt: message.createdDate,
    );
  }

  // =========================================================
  // SAVE MESSAGES
  // =========================================================

  Future<void> saveMessages({
    required String userId,
    required String conversationId,
    required Iterable<Message> messages,
  }) async {
    if (messages.isEmpty) return;

    final type = _messageEntityType(conversationId);

    await _localCacheService.putMany(
      type: type,
      scope: _scope(userId),
      entities: messages.map((message) {
        return CachedEntityInput(
          id: message.id,
          data: message.toJson(),
          searchableText: message.content.toLowerCase(),
          metadata: {
            'conversationId': conversationId,
            'sender': message.sender,
            'messageType': message.messageType.name,
            'createdAt': message.createdDate?.toIso8601String(),
          },
          remoteUpdatedAt: message.createdDate,
        );
      }),
    );
  }

  // =========================================================
  // GET MESSAGES
  // =========================================================

  Future<List<Message>> getMessages({
    required String userId,
    required String conversationId,
    int limit = 200,
  }) async {
    final rows = await _localCacheService.list(
      type: _messageEntityType(conversationId),
      scope: _scope(userId),
      limit: limit,
      offset: 0,
    );

    final messages = <Message>[];

    for (final row in rows) {
      try {
        messages.add(Message.fromJson(row));
      } catch (_) {
        // Skip invalid local records.
      }
    }

    messages.sort((a, b) {
      final aDate = a.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);

      return aDate.compareTo(bDate);
    });

    return messages;
  }

  // =========================================================
  // WATCH CONVERSATIONS
  // =========================================================

  Stream<List<Conversation>> watchConversations({required String userId}) {
    return _localCacheService
        .watch(type: _conversationType, scope: _scope(userId))
        .map((rows) {
          final result = <Conversation>[];

          for (final row in rows) {
            try {
              result.add(Conversation.fromJson(row));
            } catch (_) {}
          }

          return List<Conversation>.unmodifiable(result);
        });
  }

  // =========================================================
  // WATCH MESSAGES
  // =========================================================

  Stream<List<Message>> watchMessages({
    required String userId,
    required String conversationId,
  }) {
    return _localCacheService
        .watch(type: _messageEntityType(conversationId), scope: _scope(userId))
        .map((rows) {
          final result = <Message>[];

          for (final row in rows) {
            try {
              result.add(Message.fromJson(row));
            } catch (_) {}
          }

          result.sort((a, b) {
            final aDate =
                a.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);

            return aDate.compareTo(bDate);
          });

          return List<Message>.unmodifiable(result);
        });
  }

  // =========================================================
  // DELETE CONVERSATION
  // =========================================================

  Future<void> removeConversation({
    required String userId,
    required String conversationId,
  }) async {
    final scope = _scope(userId);

    await _localCacheService.remove(
      type: _conversationType,
      id: conversationId,
      scope: scope,
    );

    await _localCacheService.clearType(
      type: _messageEntityType(conversationId),
      scope: scope,
    );
  }

  // =========================================================
  // CLEAR USER CACHE
  // =========================================================

  Future<void> clearConversations({required String userId}) {
    return _localCacheService.clearType(
      type: _conversationType,
      scope: _scope(userId),
    );
  }

  // =========================================================
  // CACHE STATUS
  // =========================================================

  Future<bool> hasCachedConversations({required String userId}) {
    return _localCacheService.hasData(
      type: _conversationType,
      scope: _scope(userId),
    );
  }

  Future<bool> isConversationCacheStale({
    required String userId,
    Duration maxAge = const Duration(minutes: 5),
  }) {
    return _localCacheService.isStale(
      type: _conversationType,
      scope: _scope(userId),
      maxAge: maxAge,
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _messageEntityType(String conversationId) {
    return '$_messageType:${conversationId.trim()}';
  }

  String _conversationSearchText(Conversation conversation, String userId) {
    final other = conversation.getOtherParticipant(userId);

    return [
      conversation.getDisplayName(userId),
      other?.name ?? '',
      other?.email ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  Map<String, dynamic> _conversationMetadata(
    Conversation conversation,
    String userId,
  ) {
    final other = conversation.getOtherParticipant(userId);

    return {
      'otherUserId': other?.id,
      'verified': other?.verified ?? false,
      'updatedAt': _conversationUpdatedAt(conversation)?.toIso8601String(),
    };
  }

  DateTime? _conversationUpdatedAt(Conversation conversation) {
    // Replace this with the actual field if your model exposes:
    //
    // conversation.updatedAt
    // conversation.lastMessageAt
    // conversation.lastMessage?.createdDate
    //
    // Returning null is valid for the generic cache service.
    return null;
  }
}
