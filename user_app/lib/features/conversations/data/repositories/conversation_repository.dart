import 'package:user_app/shared/models/paginated_response.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/conversations/data/models/conversation.dart';
import 'package:user_app/features/conversations/data/models/message.dart';

final class ConversationRepository {
  ConversationRepository(this._api);
  final BackendApiService _api;

  Future<PaginatedResponse<Conversation>> list({
    int page = 1,
    int perPage = 20,
    String? search,
    DateTime? recentSince,
  }) => _list('/api/v2/conversations', Conversation.fromJson, page, perPage, {
    'search': ?search,
    if (recentSince != null)
      'recent_since': recentSince.toUtc().toIso8601String(),
    'sort': 'last_activity',
    'order': 'desc',
  });

  Future<Conversation> findOrCreate(String otherParticipantId) => _write(
    '/api/v2/conversations',
    'POST',
    Conversation.fromJson,
    {'other_participant_id': otherParticipantId},
  );

  Future<void> delete(String id) => _api
      .requestJson('/api/v2/conversations/$id', method: 'DELETE')
      .then((_) {});

  Future<PaginatedResponse<Message>> messages(
    String conversationId, {
    int page = 1,
    int perPage = 100,
  }) => _list(
    '/api/v2/conversations/$conversationId/messages',
    Message.fromJson,
    page,
    perPage,
    {'order': 'asc'},
  );

  Future<Message> send(
    String conversationId, {
    required String content,
    required String messageType,
    String? replyToId,
    List<String>? attachments,
  }) => _write(
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
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : response;
}
