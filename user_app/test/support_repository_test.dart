import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/models/models.dart';
import 'package:user_app/app/data/repositories/support_repository.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';

class FakeSupportApi extends BackendApiService {
  String? path;
  String? method;
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
    this.method = method;
    this.body = body;
    this.query = query;
    final item = {
      'id': 'ticket-1',
      'user_id': 'user-1',
      'subject': 'Cannot sign in',
      'description': 'Login fails',
      'status': 'in_progress',
      'priority': 'high',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-02T00:00:00Z',
    };
    if (method == 'GET' && path == '/api/v2/support/tickets') {
      return {
        'data': {
          'items': [item],
          'page': 1,
          'per_page': 20,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    return {'data': item};
  }
}

void main() {
  test('SupportRepository uses typed filters and maps ticket status', () async {
    final api = FakeSupportApi();
    final result = await SupportRepository(api).listTickets(
      search: 'login',
      status: TicketStatus.inProgress,
      priority: TicketPriority.high,
    );

    expect(api.path, '/api/v2/support/tickets');
    expect(api.query?['status'], 'in_progress');
    expect(api.query?['priority'], 'high');
    expect(result.items.single.status, TicketStatus.inProgress);
  });

  test(
    'SupportRepository never sends a client-provided ticket owner',
    () async {
      final api = FakeSupportApi();
      await SupportRepository(api).createTicket(
        subject: 'Cannot sign in',
        description: 'Login fails',
        priority: TicketPriority.high,
      );

      expect(api.path, '/api/v2/support/tickets');
      expect(api.method, 'POST');
      expect(api.body?.containsKey('user_id'), isFalse);
      expect(api.body?['priority'], 'high');
    },
  );
}
