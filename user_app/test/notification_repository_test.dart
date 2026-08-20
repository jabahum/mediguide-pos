import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/notifications/data/repositories/notification_local_repository.dart';
import 'helpers/test_local_store.dart';

class FakeNotificationApi extends BackendApiService {
  int? requestedPage;
  String? requestedSearch;
  String? markedReadId;
  String? requestedPath;
  Map<String, dynamic>? requestedBody;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    requestedPath = path;
    requestedBody = body;
    if (path == '/api/v2/notification-preferences') {
      return {
        'data': {
          'clinical_content_updates': body?['clinical_content_updates'] ?? true,
          'outbreak_alerts': true,
          'emergency_alerts': true,
          'reminders': true,
          'system_notices': true,
          'product_announcements': true,
          'quiet_hours_enabled': false,
          'quiet_hours_timezone': 'Africa/Kampala',
          'preferred_language': 'en',
          'push_enabled': true,
          'in_app_enabled': true,
        },
      };
    }
    if (path == '/api/v2/firebase/devices' && method == 'GET') {
      return {
        'data': [
          {
            'id': 'device-1',
            'installation_id': 'installation-1',
            'platform': 'android',
            'app_version': '2.0.24+51',
            'notifications_enabled': true,
            'last_seen_at': '2026-08-20T10:00:00Z',
          },
        ],
      };
    }
    if (path == '/api/v2/firebase/devices/device-1') {
      return {
        'data': {
          'id': 'device-1',
          'installation_id': 'installation-1',
          'platform': 'android',
          'notifications_enabled': body?['notifications_enabled'],
          'last_seen_at': '2026-08-20T10:00:00Z',
        },
      };
    }
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
              'action': {
                'type': 'internal_route',
                'route': '/tools',
                'parameters': <String, String>{},
              },
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
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = NotificationRepository(
        api,
        NotificationLocalRepository(store.cache),
        userId: 'user-1',
      );

      final result = await repository.list(
        page: 2,
        perPage: 10,
        search: 'maintenance',
      );

      expect(api.requestedPage, 2);
      expect(api.requestedSearch, 'maintenance');
      expect(result.items.single.title, 'Maintenance');
      expect(result.items.single.isRead, isFalse);
      expect(result.items.single.action?['type'], 'internal_route');
      expect(result.items.single.action?['route'], '/tools');
    },
  );

  test(
    'NotificationRepository delegates owner read state to the typed API',
    () async {
      final api = FakeNotificationApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = NotificationRepository(
        api,
        NotificationLocalRepository(store.cache),
        userId: 'user-1',
      );

      final result = await repository.markRead('notice-1');

      expect(api.markedReadId, 'notice-1');
      expect(result.isRead, isTrue);
    },
  );

  test('NotificationRepository loads and updates owned preferences', () async {
    final api = FakeNotificationApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = NotificationRepository(
      api,
      NotificationLocalRepository(store.cache),
      userId: 'user-1',
    );

    final initial = await repository.getPreferences();
    expect(initial.pushEnabled, isTrue);
    expect(initial.quietHoursTimezone, 'Africa/Kampala');

    final updated = await repository.updatePreferences({
      'clinical_content_updates': false,
    });
    expect(updated.clinicalContentUpdates, isFalse);
    expect(api.requestedPath, '/api/v2/notification-preferences');
    expect(api.requestedBody, {'clinical_content_updates': false});
  });

  test(
    'NotificationRepository manages token-free device projections',
    () async {
      final api = FakeNotificationApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = NotificationRepository(
        api,
        NotificationLocalRepository(store.cache),
        userId: 'user-1',
      );

      final devices = await repository.listDevices();
      expect(devices.single.platform, 'android');
      expect(devices.single.notificationsEnabled, isTrue);

      final updated = await repository.setDevicePushEnabled('device-1', false);
      expect(updated.notificationsEnabled, isFalse);
      expect(api.requestedBody, {'notifications_enabled': false});
    },
  );

  test(
    'NotificationRepository records typed delivery events without user ids',
    () async {
      final api = FakeNotificationApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = NotificationRepository(
        api,
        NotificationLocalRepository(store.cache),
        userId: 'user-1',
      );

      await repository.recordOpen('delivery-1', eventId: 'push-open-message-1');

      expect(
        api.requestedPath,
        '/api/v2/notification-deliveries/delivery-1/open',
      );
      expect(api.requestedBody?['event_id'], 'push-open-message-1');
      expect(api.requestedBody?.containsKey('user_id'), isFalse);
      expect(api.requestedBody?['occurred_at'], isNotEmpty);
    },
  );
}
