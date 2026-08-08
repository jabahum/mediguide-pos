import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:user_app/features/support/data/repositories/support_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/support/presentation/controllers/help_center_controller.dart';
import 'package:user_app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/notifications/data/repositories/notification_local_repository.dart';
import 'package:user_app/features/support/data/repositories/support_local_repository.dart';
import 'helpers/test_local_store.dart';

class SupportNotificationsApi extends BackendApiService {
  String? lastPath;
  String? lastMethod;
  Map<String, String>? lastQuery;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    lastPath = path;
    lastMethod = method;
    lastQuery = query;

    if (path == '/api/v2/support/tickets') {
      return {
        'data': {
          'items': [_ticket],
          'page': 1,
          'per_page': 30,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    if (path == '/api/v2/support/tickets/ticket-1') {
      return {'data': _ticket};
    }
    if (path == '/api/v2/support/tickets/ticket-1/replies') {
      return {
        'data': {
          'items': [_reply],
          'page': 1,
          'per_page': 100,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    if (path == '/api/v2/notifications/notice-1/read') {
      return {
        'data': {..._notification, 'is_read': true},
      };
    }
    if (path == '/api/v2/notifications') {
      return {
        'data': {
          'items': [_notification],
          'page': 1,
          'per_page': 20,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    throw StateError('Unexpected request: $method $path');
  }

  static final _ticket = <String, dynamic>{
    'id': 'ticket-1',
    'user_id': 'user-1',
    'subject': 'Cannot sign in',
    'description': 'The login request fails',
    'category': 'Account Problem',
    'status': 'inProgress',
    'priority': 'high',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-02T00:00:00Z',
  };

  static final _reply = <String, dynamic>{
    'id': 'reply-1',
    'ticket_id': 'ticket-1',
    'user_id': 'user-1',
    'message': 'Please help',
    'is_internal': false,
    'created_at': '2026-01-02T00:00:00Z',
    'updated_at': '2026-01-02T00:00:00Z',
  };

  static final _notification = <String, dynamic>{
    'id': 'notice-1',
    'title': 'Maintenance',
    'message': 'Tonight',
    'type': 'warning',
    'priority': 'high',
    'is_read': false,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('support notifier sends explicit typed filters', () async {
    final api = SupportNotificationsApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = SupportRepository(
      api,
      SupportLocalRepository(store.cache),
      userId: 'user-1',
    );
    final container = ProviderContainer(
      overrides: [supportRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(helpCenterControllerProvider, (_, _) {});
    final controller = container.read(helpCenterControllerProvider.notifier);

    controller.updateSearchQuery('login');
    controller.updateStatusFilter('inProgress');
    controller.updatePriorityFilter('high');
    controller.updateCategoryFilter('Account Problem');
    final tickets = await controller.loadTicketsPage(1);

    expect(
      container.read(helpCenterControllerProvider).hasActiveFilters,
      isTrue,
    );
    expect(tickets.single.id, 'ticket-1');
    expect(api.lastPath, '/api/v2/support/tickets');
    expect(api.lastQuery?['search'], 'login');
    expect(api.lastQuery?['status'], 'in_progress');
    expect(api.lastQuery?['priority'], 'high');
    expect(api.lastQuery?['category'], 'Account Problem');
  });

  test('support notifier loads a ticket and its typed replies', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = SupportRepository(
      SupportNotificationsApi(),
      SupportLocalRepository(store.cache),
      userId: 'user-1',
    );
    final container = ProviderContainer(
      overrides: [supportRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(helpCenterControllerProvider, (_, _) {});
    final controller = container.read(helpCenterControllerProvider.notifier);

    await controller.loadTicketDetails('ticket-1');

    final state = container.read(helpCenterControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.selectedTicket?.id, 'ticket-1');
    expect(state.currentTicketReplies.single.id, 'reply-1');
  });

  test('notification notifier owns filters and read commands', () async {
    final api = SupportNotificationsApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = NotificationRepository(
      api,
      NotificationLocalRepository(store.cache),
      userId: 'user-1',
    );
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(notificationsControllerProvider, (_, _) {});
    final controller = container.read(notificationsControllerProvider.notifier);

    controller.setTypeFilter('warning');
    controller.setPriorityFilter('high');

    var state = container.read(notificationsControllerProvider);
    expect(state.hasActiveFilters, isTrue);
    expect(state.selectedType, 'warning');
    expect(state.selectedPriority, 'high');

    const notification = MyNotification(
      id: 'notice-1',
      title: 'Maintenance',
      message: 'Tonight',
    );
    await controller.markRead(notification);

    expect(api.lastPath, '/api/v2/notifications/notice-1/read');
    expect(api.lastMethod, 'POST');

    controller.clearAllFilters();
    state = container.read(notificationsControllerProvider);
    expect(state.hasActiveFilters, isFalse);
  });
}
