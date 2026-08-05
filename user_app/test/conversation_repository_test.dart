import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/core/network/api_client.dart';

class FakeConversationApi extends BackendApiService {
  String? path;
  Map<String, dynamic>? body;
  Map<String, String>? query;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    this.path = path;
    this.body = body;
    this.query = query;
    if (path.endsWith('/messages') && method == 'GET') {
      return {
        'data': {
          'items': [
            {
              'id': 'message-1',
              'conversation_id': 'conversation-1',
              'sender_user_id': 'user-1',
              'sender_name': 'Clinician',
              'content': 'Hello',
              'message_type': 'text',
              'attachments': [],
              'read_by': {},
              'reactions': {},
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          ],
          'page': 1,
          'per_page': 100,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    return {
      'data': {
        'id': 'message-1',
        'conversation_id': 'conversation-1',
        'sender_user_id': 'server-owned-user',
        'content': body?['content'] ?? '',
        'message_type': body?['message_type'] ?? 'text',
        'attachments': [],
        'read_by': {},
        'reactions': {},
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      },
    };
  }
}

void main() {
  test(
    'messages use nested participant-protected routes and explicit order',
    () async {
      final api = FakeConversationApi();
      final result = await ConversationRepository(
        api,
      ).messages('conversation-1');
      expect(api.path, '/api/v2/conversations/conversation-1/messages');
      expect(api.query?['order'], 'asc');
      expect(api.query?.containsKey('filter'), isFalse);
      expect(result.items.single.sender, 'user-1');
    },
  );

  test('message creation does not send a client sender id', () async {
    final api = FakeConversationApi();
    await ConversationRepository(
      api,
    ).send('conversation-1', content: 'Hello', messageType: 'text');
    expect(api.body?['content'], 'Hello');
    expect(api.body?.containsKey('sender_user_id'), isFalse);
    expect(api.body?.containsKey('sender'), isFalse);
  });
}
