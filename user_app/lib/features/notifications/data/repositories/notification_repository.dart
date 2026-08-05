import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

final class NotificationRepository {
  NotificationRepository(this._api);

  final BackendApiService _api;

  Future<PagedResult<MyNotification>> list({
    required int page,
    required int perPage,
    String? search,
    String? type,
    String? priority,
    bool? isRead,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/notifications',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (_present(search)) 'search': search!.trim(),
        if (_present(type)) 'type': type!,
        if (_present(priority)) 'priority': priority!,
        if (isRead != null) 'is_read': '$isRead',
        'sort': 'created_at',
        'order': 'desc',
      },
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (value) => MyNotification.fromJson(Map<String, dynamic>.from(value)),
        )
        .toList();
    return PagedResult<MyNotification>(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<MyNotification> markRead(String id) => _changeReadState(id, 'read');

  Future<MyNotification> markUnread(String id) =>
      _changeReadState(id, 'unread');

  Future<void> markAllRead() async {
    await _api.requestJson('/api/v2/notifications/read-all', method: 'POST');
  }

  Future<MyNotification> _changeReadState(String id, String state) async {
    final response = await _api.requestJson(
      '/api/v2/notifications/$id/$state',
      method: 'POST',
    );
    final data = _data(response);
    return MyNotification.fromJson(data);
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  static bool _present(String? value) => value?.trim().isNotEmpty == true;
}
