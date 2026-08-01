import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/repositories/notification_repository.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';

class FakeNotificationApi extends BackendApiService {
  int? requestedPage;
  String? requestedSearch;
  String? markedReadId;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    if (path == '/api/v2/notifications') {
      requestedPage = int.parse(query!['page']!);
      requestedSearch = query['search'];
      return {
        'data': {
          'page': requestedPage,
          'per_page': int.parse(query['per_page']!),
          'total_items': 1,
          'total_pages': 1,
          'items': [
            {
              'id': 'notice-1',
              'title': 'Maintenance',
              'message': 'Tonight',
              'type': 'warning',
              'priority': 'high',
              'is_read': false,
            },
          ],
        },
      };
    }
    markedReadId = path.split('/')[4];
    return {
      'data': {
        'id': markedReadId,
        'title': 'Maintenance',
        'message': 'Tonight',
        'type': 'warning',
        'priority': 'high',
        'is_read': true,
      },
    };
  }
}

void main() {
  test(
    'NotificationRepository maps typed pages to application models',
    () async {
      final api = FakeNotificationApi();
      final repository = NotificationRepository(api);

      final result = await repository.list(
        page: 2,
        perPage: 10,
        search: 'maintenance',
      );

      expect(api.requestedPage, 2);
      expect(api.requestedSearch, 'maintenance');
      expect(result.items.single.title, 'Maintenance');
      expect(result.items.single.isRead, isFalse);
    },
  );

  test(
    'NotificationRepository delegates owner read state to the typed API',
    () async {
      final api = FakeNotificationApi();
      final repository = NotificationRepository(api);

      final result = await repository.markRead('notice-1');

      expect(api.markedReadId, 'notice-1');
      expect(result.isRead, isTrue);
    },
  );
}
