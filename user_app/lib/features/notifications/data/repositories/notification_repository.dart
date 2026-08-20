import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

import 'package:user_app/features/notifications/data/repositories/notification_local_repository.dart';
import 'package:user_app/features/notifications/data/models/notification_preferences.dart';

final class NotificationRepository {
  NotificationRepository(this._api, this._local, {required this.userId});

  final BackendApiService _api;
  final NotificationLocalRepository _local;

  /// Notifications are private user data, so all persistent cache
  /// operations are scoped to the authenticated user.
  final String userId;

  Future<NotificationPreferences> getPreferences() async {
    final response = await _api.requestJson(
      '/api/v2/notification-preferences',
      method: 'GET',
    );
    return NotificationPreferences.fromJson(_data(response));
  }

  Future<NotificationPreferences> updatePreferences(
    Map<String, dynamic> changes,
  ) async {
    final response = await _api.requestJson(
      '/api/v2/notification-preferences',
      method: 'PATCH',
      body: changes,
    );
    return NotificationPreferences.fromJson(_data(response));
  }

  Future<List<NotificationDevice>> listDevices() async {
    final response = await _api.requestJson(
      '/api/v2/firebase/devices',
      method: 'GET',
    );
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (value) =>
              NotificationDevice.fromJson(Map<String, dynamic>.from(value)),
        )
        .where((device) => device.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<NotificationDevice> setDevicePushEnabled(
    String deviceId,
    bool enabled,
  ) async {
    final response = await _api.requestJson(
      '/api/v2/firebase/devices/${Uri.encodeComponent(deviceId)}',
      method: 'PATCH',
      body: {'notifications_enabled': enabled},
    );
    return NotificationDevice.fromJson(_data(response));
  }

  // =========================================================
  // LIST
  // =========================================================

  Future<PaginatedResponse<MyNotification>> list({
    required int page,
    required int perPage,
    String? search,
    String? type,
    String? priority,
    bool? isRead,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 20 : perPage;

    // Best-effort upload of offline read/unread changes.
    await syncPending();

    try {
      final response = await _api.requestJson(
        '/api/v2/notifications',
        method: 'GET',
        query: {
          'page': '$safePage',
          'per_page': '$safePerPage',
          if (_present(search)) 'search': search!.trim(),
          if (_present(type)) 'type': type!.trim(),
          if (_present(priority)) 'priority': priority!.trim(),
          if (isRead != null) 'is_read': '$isRead',
          'sort': 'created_at',
          'order': 'desc',
        },
      );

      final data = _data(response);

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) =>
                MyNotification.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);

      // Persist successful API response without allowing cache
      // failures to break the online request.
      try {
        await _saveRemoteNotifications(items);
      } catch (_) {}

      return PaginatedResponse<MyNotification>(
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
        items: items,
      );
    } catch (_) {
      // =======================================================
      // OFFLINE FALLBACK
      // =======================================================

      final cached = await _local.getNotifications(
        userId: userId,
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        type: type ?? '',
        priority: priority ?? '',
        isRead: isRead,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<MyNotification>(
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: _totalPages(cached.length, safePerPage),
        items: cached,
      );
    }
  }

  // =========================================================
  // MARK READ
  // =========================================================

  Future<MyNotification> markRead(String id) {
    return _changeReadState(id, 'read', isRead: true);
  }

  // =========================================================
  // MARK UNREAD
  // =========================================================

  Future<MyNotification> markUnread(String id) {
    return _changeReadState(id, 'unread', isRead: false);
  }

  Future<void> recordOpen(String deliveryId, {required String eventId}) {
    return _recordDeliveryEvent(deliveryId, 'open', eventId);
  }

  Future<void> recordClick(String deliveryId, {required String eventId}) {
    return _recordDeliveryEvent(deliveryId, 'click', eventId);
  }

  Future<void> _recordDeliveryEvent(
    String deliveryId,
    String eventType,
    String eventId,
  ) async {
    final id = deliveryId.trim();
    if (id.isEmpty) return;
    await _api.requestJson(
      '/api/v2/notification-deliveries/${Uri.encodeComponent(id)}/$eventType',
      method: 'POST',
      body: {
        'event_id': eventId,
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  // =========================================================
  // CHANGE READ STATE
  // =========================================================
  //
  // Local-first:
  //
  // 1. update Drift immediately
  // 2. mark pending_sync
  // 3. attempt API request
  // 4. replace local copy with server response
  //
  // This means read/unread state remains functional offline.
  // =========================================================

  Future<MyNotification> _changeReadState(
    String id,
    String state, {
    required bool isRead,
  }) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Notification id is required');
    }

    final existing = await _local.getNotification(
      userId: userId,
      notificationId: normalizedId,
    );

    // ---------------------------------------------------------
    // Apply local mutation first.
    // ---------------------------------------------------------

    MyNotification? optimistic;

    if (existing != null) {
      final json = existing.toJson();

      final now = DateTime.now().toUtc().toIso8601String();

      final updated = <String, dynamic>{
        ...json,
        'is_read': isRead,
        'read': isRead,
        'read_at': isRead ? (json['read_at'] ?? now) : null,
        'updated_at': now,
        'pending_sync': true,
        'pending_read_state': state,
      };

      try {
        optimistic = MyNotification.fromJson(updated);

        await _local.saveNotification(
          userId: userId,
          notification: optimistic,
          pendingSync: true,
        );
      } catch (_) {
        optimistic = existing;
      }
    }

    try {
      final response = await _api.requestJson(
        '/api/v2/notifications/${Uri.encodeComponent(normalizedId)}/$state',
        method: 'POST',
      );

      final notification = MyNotification.fromJson(_data(response));

      // Server has confirmed the mutation.
      await _local.saveNotification(
        userId: userId,
        notification: notification,
        pendingSync: false,
      );

      return notification;
    } catch (_) {
      // Offline/local success.
      //
      // Keep pending_sync so it can be retried later.
      if (optimistic != null) {
        return optimistic;
      }

      rethrow;
    }
  }

  // =========================================================
  // MARK ALL READ
  // =========================================================

  Future<void> markAllRead() async {
    // ---------------------------------------------------------
    // Update local notifications first.
    // ---------------------------------------------------------

    final cached = await _local.getNotifications(
      userId: userId,
      page: 1,
      perPage: 1000,
    );

    for (final notification in cached) {
      if (notification.isRead) continue;

      try {
        final json = notification.toJson();

        final now = DateTime.now().toUtc().toIso8601String();

        final updated = MyNotification.fromJson({
          ...json,
          'is_read': true,
          'read': true,
          'read_at': json['read_at'] ?? now,
          'updated_at': now,
          'pending_sync': true,
          'pending_read_state': 'read',
        });

        await _local.saveNotification(
          userId: userId,
          notification: updated,
          pendingSync: true,
        );
      } catch (_) {
        // Continue applying changes to remaining notifications.
      }
    }

    try {
      await _api.requestJson('/api/v2/notifications/read-all', method: 'POST');

      // -------------------------------------------------------
      // Server confirmed all notifications are read.
      // Mark all locally cached notifications as synced.
      // -------------------------------------------------------

      final pending = await _local.pendingSync(userId: userId);

      for (final record in pending) {
        final id = record['id']?.toString().trim() ?? '';

        if (id.isEmpty) continue;

        await _local.markSynced(userId: userId, notificationId: id);
      }
    } catch (_) {
      // Keep pending records.
      //
      // syncPending() will retry individual read operations later.
    }
  }

  // =========================================================
  // SYNC PENDING
  // =========================================================

  Future<void> syncPending() async {
    if (userId.trim().isEmpty) return;

    final pending = await _local.pendingSync(userId: userId);

    for (final record in pending) {
      final id = record['id']?.toString().trim() ?? '';

      if (id.isEmpty) {
        continue;
      }

      final state = _pendingState(record);

      try {
        final response = await _api.requestJson(
          '/api/v2/notifications/${Uri.encodeComponent(id)}/$state',
          method: 'POST',
        );

        final notification = MyNotification.fromJson(_data(response));

        await _local.saveNotification(
          userId: userId,
          notification: notification,
          pendingSync: false,
        );
      } catch (_) {
        // Keep pending_sync=true and retry later.
      }
    }
  }

  // =========================================================
  // SAVE REMOTE NOTIFICATIONS
  // =========================================================
  //
  // Important conflict rule:
  //
  // A remote "unread" record must not overwrite a local
  // pending "read" mutation that has not yet reached the server.
  // =========================================================

  Future<void> _saveRemoteNotifications(
    Iterable<MyNotification> notifications,
  ) async {
    for (final remote in notifications) {
      final localRecord = await _local.getRecord(
        userId: userId,
        notificationId: remote.id,
      );

      // No local mutation pending -> remote wins.
      if (localRecord == null || localRecord['pending_sync'] != true) {
        await _local.saveNotification(
          userId: userId,
          notification: remote,
          pendingSync: false,
        );

        continue;
      }

      // -------------------------------------------------------
      // Preserve local pending mutation.
      // -------------------------------------------------------

      final pendingState = _pendingState(localRecord);

      final remoteJson = remote.toJson();

      final merged = <String, dynamic>{
        ...remoteJson,

        // Preserve pending local read state.
        'is_read': pendingState == 'read',
        'read': pendingState == 'read',

        if (pendingState == 'read')
          'read_at': localRecord['read_at'] ?? remoteJson['read_at'],

        if (pendingState == 'unread') 'read_at': null,

        'pending_sync': true,
        'pending_read_state': pendingState,
      };

      try {
        final mergedNotification = MyNotification.fromJson(merged);

        await _local.saveNotification(
          userId: userId,
          notification: mergedNotification,
          pendingSync: true,
        );
      } catch (_) {
        // Keep existing local pending record untouched.
      }
    }
  }

  // =========================================================
  // PENDING STATE
  // =========================================================

  String _pendingState(Map<String, dynamic> record) {
    final explicit = record['pending_read_state']
        ?.toString()
        .trim()
        .toLowerCase();

    if (explicit == 'read' || explicit == 'unread') {
      return explicit!;
    }

    final isRead = record['is_read'] == true || record['read'] == true;

    return isRead ? 'read' : 'unread';
  }

  // =========================================================
  // UNREAD COUNT
  // =========================================================

  Future<int> unreadCount() async {
    try {
      final response = await _api.requestJson(
        '/api/v2/notifications',
        method: 'GET',
        query: const {
          'page': '1',
          'per_page': '1',
          'is_read': 'false',
          'sort': 'created_at',
          'order': 'desc',
        },
      );

      final data = _data(response);

      return (data['total_items'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return _local.unreadCount(userId: userId);
    }
  }

  // =========================================================
  // LOCAL CACHE
  // =========================================================

  Future<bool> hasCachedNotifications() {
    return _local.hasCachedNotifications(userId: userId);
  }

  Future<bool> isCacheStale({Duration maxAge = const Duration(minutes: 15)}) {
    return _local.isCacheStale(userId: userId, maxAge: maxAge);
  }

  Future<void> clearLocalCache() {
    return _local.clear(userId: userId);
  }

  // =========================================================
  // HELPERS
  // =========================================================

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];

    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  static bool _present(String? value) {
    return value?.trim().isNotEmpty == true;
  }

  static int _totalPages(int totalItems, int perPage) {
    if (totalItems <= 0 || perPage <= 0) {
      return 0;
    }

    return (totalItems / perPage).ceil();
  }
}
