import 'package:user_app/shared/models/paginated_response.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/conversations/data/models/conversation.dart';
import 'package:user_app/features/conversations/data/models/message.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_local_repository.dart';

final class ConversationRepository {
  ConversationRepository(this._api, this._local, {required this.userId});
  final BackendApiService _api;
  final ConversationLocalRepository _local;
  final String userId;

  Future<PaginatedResponse<Conversation>> list({
    int page = 1,
    int perPage = 20,
    String? search,
    DateTime? recentSince,
  }) async {
    _requireUser();
    try {
      final result = await _list(
        '/api/v2/conversations',
        Conversation.fromJson,
        page,
        perPage,
        {
          'search': ?search,
          if (recentSince != null)
            'recent_since': recentSince.toUtc().toIso8601String(),
          'sort': 'last_activity',
          'order': 'desc',
        },
      );
      await _bestEffort(
        () => _local.saveConversations(
          userId: userId,
          conversations: result.items,
        ),
      );
      return result;
    } catch (_) {
      final cached = await _local.listConversations(
        userId: userId,
        page: page,
        perPage: perPage,
        search: search ?? '',
        recentSince: recentSince,
      );
      if (cached.items.isEmpty) rethrow;
      return PaginatedResponse(
        items: cached.items,
        page: cached.page,
        perPage: cached.perPage,
        totalItems: cached.totalItems,
        totalPages: cached.totalPages,
      );
    }
  }

  Future<Conversation> get(String id) async {
    _requireUser();
    try {
      final conversation = await _read(
        '/api/v2/conversations/$id',
        Conversation.fromJson,
      );
      await _bestEffort(
        () =>
            _local.saveConversation(userId: userId, conversation: conversation),
      );
      return conversation;
    } catch (_) {
      final cached = await _local.getConversation(
        userId: userId,
        conversationId: id,
      );
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<Conversation> findOrCreate(String otherParticipantId) async {
    _requireUser();
    final conversation = await _write(
      '/api/v2/conversations',
      'POST',
      Conversation.fromJson,
      {'other_participant_id': otherParticipantId},
    );
    await _bestEffort(
      () => _local.saveConversation(userId: userId, conversation: conversation),
    );
    return conversation;
  }

  Future<void> delete(String id) async {
    _requireUser();
    await _api.requestJson('/api/v2/conversations/$id', method: 'DELETE');
    await _bestEffort(
      () => _local.removeConversation(userId: userId, conversationId: id),
    );
  }

  Future<PaginatedResponse<Message>> messages(
    String conversationId, {
    int page = 1,
    int perPage = 100,
  }) async {
    _requireUser();
    try {
      final result = await _list(
        '/api/v2/conversations/$conversationId/messages',
        Message.fromJson,
        page,
        perPage,
        {'order': 'asc'},
      );
      await _bestEffort(
        () => _local.saveMessages(
          userId: userId,
          conversationId: conversationId,
          messages: result.items,
        ),
      );
      return result;
    } catch (_) {
      final cached = await _local.messagePage(
        userId: userId,
        conversationId: conversationId,
        page: page,
        perPage: perPage,
      );
      if (cached.items.isEmpty) rethrow;
      return PaginatedResponse(
        items: cached.items,
        page: cached.page,
        perPage: cached.perPage,
        totalItems: cached.totalItems,
        totalPages: cached.totalPages,
      );
    }
  }

  Future<Message> send(
    String conversationId, {
    required String content,
    required String messageType,
    String? replyToId,
    List<String>? attachments,
  }) async {
    _requireUser();
    final message = await _write(
      '/api/v2/conversations/$conversationId/messages',
      'POST',
      Message.fromJson,
      {
        'content': content,
        'message_type': messageType,
        'reply_to_id': ?replyToId,
        'attachments': ?attachments,
      },
    );
    await _bestEffort(
      () => _local.saveMessage(
        userId: userId,
        conversationId: conversationId,
        message: message,
      ),
    );
    return message;
  }

  Future<Message> markRead(
    String conversationId,
    String messageId,
    DateTime readAt,
  ) => _write(
    '/api/v2/conversations/$conversationId/messages/$messageId/read',
    'POST',
    Message.fromJson,
    {'read_at': readAt.toUtc().toIso8601String()},
  );

  Future<Message> react(
    String conversationId,
    String messageId,
    String emoji, {
    required bool active,
  }) => _write(
    '/api/v2/conversations/$conversationId/messages/$messageId/reaction',
    'POST',
    Message.fromJson,
    {'emoji': emoji, 'active': active},
  );

  Future<PaginatedResponse<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
    int page,
    int perPage,
    Map<String, String> query,
  ) async {
    final data = _data(
      await _api.requestJson(
        path,
        method: 'GET',
        query: {'page': '$page', 'per_page': '$perPage', ...query},
      ),
    );
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => fromJson(Map<String, dynamic>.from(value)))
        .toList();
    return PaginatedResponse(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<T> _write<T>(
    String path,
    String method,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> body,
  ) async {
    final response = await _api.requestJson(path, method: method, body: body);
    return fromJson(_data(response));
  }

  Future<T> _read<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _api.requestJson(path, method: 'GET');
    final data = _data(response);
    final item = data['item'];
    return fromJson(item is Map ? Map<String, dynamic>.from(item) : data);
  }

  void _requireUser() {
    if (userId.trim().isEmpty) {
      throw StateError('Authenticated user is required for conversations');
    }
  }

  Future<void> _bestEffort(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // Private cache persistence is best effort after remote success.
    }
  }
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : response;
}
