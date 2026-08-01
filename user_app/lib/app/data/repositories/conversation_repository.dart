import '../models/api_record.dart';
import '../services/backend_api_service.dart';

final class ConversationRepository {
  ConversationRepository(this._api);
  final BackendApiService _api;

  Future<PagedResult<ApiRecord>> list({
    int page = 1,
    int perPage = 20,
    String? search,
    DateTime? recentSince,
  }) => _list('/api/v2/conversations', 'conversations', page, perPage, {
    'search': ?search,
    if (recentSince != null)
      'recent_since': recentSince.toUtc().toIso8601String(),
    'sort': 'last_activity',
    'order': 'desc',
  });

  Future<ApiRecord> findOrCreate(String otherParticipantId) => _write(
    '/api/v2/conversations',
    'POST',
    'conversations',
    {'other_participant_id': otherParticipantId},
  );

  Future<void> delete(String id) => _api
      .requestJson('/api/v2/conversations/$id', method: 'DELETE')
      .then((_) {});

  Future<PagedResult<ApiRecord>> messages(
    String conversationId, {
    int page = 1,
    int perPage = 100,
  }) => _list(
    '/api/v2/conversations/$conversationId/messages',
    'messages',
    page,
    perPage,
    {'order': 'asc'},
  );

  Future<ApiRecord> send(
    String conversationId, {
    required String content,
    required String messageType,
    String? replyToId,
    List<String>? attachments,
  }) => _write(
    '/api/v2/conversations/$conversationId/messages',
    'POST',
    'messages',
    {
      'content': content,
      'message_type': messageType,
      'reply_to_id': ?replyToId,
      'attachments': ?attachments,
    },
  );

  Future<ApiRecord> markRead(
    String conversationId,
    String messageId,
    DateTime readAt,
  ) => _write(
    '/api/v2/conversations/$conversationId/messages/$messageId/read',
    'POST',
    'messages',
    {'read_at': readAt.toUtc().toIso8601String()},
  );

  Future<ApiRecord> react(
    String conversationId,
    String messageId,
    String emoji, {
    required bool active,
  }) => _write(
    '/api/v2/conversations/$conversationId/messages/$messageId/reaction',
    'POST',
    'messages',
    {'emoji': emoji, 'active': active},
  );

  Future<PagedResult<ApiRecord>> _list(
    String path,
    String collection,
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
        .map(
          (value) => ApiRecord(
            _normalize(Map<String, dynamic>.from(value), collection),
          ),
        )
        .toList();
    return PagedResult(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<ApiRecord> _write(
    String path,
    String method,
    String collection,
    Map<String, dynamic> body,
  ) async {
    final response = await _api.requestJson(path, method: method, body: body);
    return ApiRecord(_normalize(_data(response), collection));
  }

  Map<String, dynamic> _normalize(
    Map<String, dynamic> value,
    String collection,
  ) {
    final data = <String, dynamic>{
      ...value,
      'created': value['created_at'] ?? value['created'] ?? '',
      'updated': value['updated_at'] ?? value['updated'] ?? '',
      'collectionId': collection,
      'collectionName': collection,
    };
    if (collection == 'conversations') {
      final p1 = value['participant1_user_id']?.toString() ?? '';
      final p2 = value['participant2_user_id']?.toString() ?? '';
      data['participant1'] = p1;
      data['participant2'] = p2;
      data['expand'] = {
        'participant1': _user(value, 'participant1', p1),
        'participant2': _user(value, 'participant2', p2),
        if ((value['last_message_id']?.toString() ?? '').isNotEmpty)
          'last_message': {
            'id': value['last_message_id'],
            'content': value['last_message'] ?? '',
          },
      };
    } else {
      final sender = value['sender_user_id']?.toString() ?? '';
      data['conversation'] = value['conversation_id']?.toString() ?? '';
      data['sender'] = sender;
      data['reply_to'] = value['reply_to_id']?.toString() ?? '';
      data['attachments'] = value['attachments'] ?? <dynamic>[];
      data['read_by'] = value['read_by'] ?? <String, dynamic>{};
      data['reactions'] = value['reactions'] ?? <String, dynamic>{};
      data['expand'] = {'sender': _user(value, 'sender', sender)};
    }
    return data;
  }

  Map<String, dynamic> _user(
    Map<String, dynamic> value,
    String prefix,
    String id,
  ) => {
    'id': id,
    'name': value['${prefix}_name'] ?? '',
    'email': value['${prefix}_email'] ?? '',
    'avatar': value['${prefix}_avatar'] ?? '',
    'verified': value['${prefix}_verified'] ?? false,
    'collectionId': 'users',
    'collectionName': 'users',
  };
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : response;
}
