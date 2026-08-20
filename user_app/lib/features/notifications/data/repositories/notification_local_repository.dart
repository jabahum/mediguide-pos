import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/shared/models/models.dart';

final notificationLocalRepositoryProvider =
    Provider<NotificationLocalRepository>((ref) {
      return NotificationLocalRepository(ref.watch(localCacheServiceProvider));
    });

final class NotificationLocalRepository {
  NotificationLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _entityType = 'notification';

  // =========================================================
  // SCOPE
  // =========================================================

  String _scope(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User id is required for notification cache',
      );
    }

    return 'user:$normalized';
  }

  // =========================================================
  // SAVE ONE
  // =========================================================

  Future<void> saveNotification({
    required String userId,
    required MyNotification notification,
    bool pendingSync = false,
  }) async {
    await _localCacheService.put(
      type: _entityType,
      id: notification.id,
      scope: _scope(userId),
      data: _withSyncState(notification.toJson(), pendingSync: pendingSync),
      searchableText: _searchableText(notification),
      metadata: _metadata(notification, pendingSync: pendingSync),
      remoteUpdatedAt: _updatedAt(notification),
    );
  }

  // =========================================================
  // SAVE MANY
  // =========================================================

  Future<void> saveNotifications({
    required String userId,
    required Iterable<MyNotification> notifications,
  }) async {
    if (notifications.isEmpty) return;

    await _localCacheService.putMany(
      type: _entityType,
      scope: _scope(userId),
      entities: notifications.map((notification) {
        return CachedEntityInput(
          id: notification.id,
          data: _withSyncState(notification.toJson(), pendingSync: false),
          searchableText: _searchableText(notification),
          metadata: _metadata(notification, pendingSync: false),
          remoteUpdatedAt: _updatedAt(notification),
        );
      }),
    );
  }

  // =========================================================
  // GET ONE
  // =========================================================

  Future<MyNotification?> getNotification({
    required String userId,
    required String notificationId,
  }) async {
    final id = notificationId.trim();

    if (id.isEmpty) return null;

    final row = await _localCacheService.get(
      type: _entityType,
      id: id,
      scope: _scope(userId),
    );

    if (row == null) return null;

    try {
      return MyNotification.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // GET RAW RECORD
  // =========================================================
  //
  // Useful when checking pending_sync state.
  // =========================================================

  Future<Map<String, dynamic>?> getRecord({
    required String userId,
    required String notificationId,
  }) {
    return _localCacheService.get(
      type: _entityType,
      id: notificationId,
      scope: _scope(userId),
    );
  }

  // =========================================================
  // LIST
  // =========================================================

  Future<List<MyNotification>> getNotifications({
    required String userId,
    int page = 1,
    int perPage = 30,
    String search = '',
    String type = '',
    String priority = '',
    bool? isRead,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    //
    // Fetch a wider local candidate set because type/priority/read
    // filtering is currently performed in Dart.
    //
    final rows = await _localCacheService.list(
      type: _entityType,
      scope: _scope(userId),
      search: search.trim(),
      limit: 1000,
      offset: 0,
    );

    final notifications = <MyNotification>[];

    for (final row in rows) {
      try {
        final notification = MyNotification.fromJson(row);

        if (!_matchesFilters(
          notification,
          type: type,
          priority: priority,
          isRead: isRead,
        )) {
          continue;
        }

        notifications.add(notification);
      } catch (_) {
        // Ignore malformed cached notification.
      }
    }

    notifications.sort(_sortNotifications);

    return _paginate(notifications, page: safePage, perPage: safePerPage);
  }

  // =========================================================
  // UNREAD
  // =========================================================

  Future<List<MyNotification>> getUnreadNotifications({
    required String userId,
    int page = 1,
    int perPage = 30,
  }) {
    return getNotifications(
      userId: userId,
      page: page,
      perPage: perPage,
      isRead: false,
    );
  }

  Future<int> unreadCount({required String userId}) async {
    final rows = await getNotifications(
      userId: userId,
      page: 1,
      perPage: 1000,
      isRead: false,
    );

    return rows.length;
  }

  Stream<int> watchUnreadCount({required String userId}) {
    return _localCacheService
        .watch(type: _entityType, scope: _scope(userId))
        .map(
          (rows) => rows.where((row) {
            return row['is_read'] != true && row['read'] != true;
          }).length,
        )
        .distinct();
  }

  // =========================================================
  // MARK READ LOCALLY
  // =========================================================

  Future<void> markRead({
    required String userId,
    required String notificationId,
    bool pendingSync = true,
  }) async {
    final existing = await getRecord(
      userId: userId,
      notificationId: notificationId,
    );

    if (existing == null) return;

    final now = DateTime.now().toUtc().toIso8601String();

    final updated = <String, dynamic>{
      ...existing,
      'is_read': true,
      'read': true,
      'read_at': existing['read_at'] ?? now,
      'updated_at': now,
      'pending_sync': pendingSync,
    };

    await _localCacheService.put(
      type: _entityType,
      id: notificationId,
      scope: _scope(userId),
      data: updated,
      searchableText: _searchableTextFromJson(updated),
      metadata: {..._metadataFromJson(updated), 'pendingSync': pendingSync},
      remoteUpdatedAt: DateTime.tryParse(now),
    );
  }

  // =========================================================
  // MARK SYNCED
  // =========================================================

  Future<void> markSynced({
    required String userId,
    required String notificationId,
  }) async {
    final existing = await getRecord(
      userId: userId,
      notificationId: notificationId,
    );

    if (existing == null) return;

    final updated = <String, dynamic>{...existing, 'pending_sync': false};

    await _localCacheService.put(
      type: _entityType,
      id: notificationId,
      scope: _scope(userId),
      data: updated,
      searchableText: _searchableTextFromJson(updated),
      metadata: {..._metadataFromJson(updated), 'pendingSync': false},
      remoteUpdatedAt: _dateOrNull(updated['updated_at']),
    );
  }

  // =========================================================
  // PENDING SYNC
  // =========================================================

  Future<List<Map<String, dynamic>>> pendingSync({
    required String userId,
  }) async {
    final rows = await _localCacheService.list(
      type: _entityType,
      scope: _scope(userId),
      limit: 1000,
      offset: 0,
    );

    return rows
        .where((row) => row['pending_sync'] == true)
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  // =========================================================
  // REMOVE
  // =========================================================

  Future<void> remove({
    required String userId,
    required String notificationId,
  }) {
    return _localCacheService.remove(
      type: _entityType,
      id: notificationId,
      scope: _scope(userId),
    );
  }

  // =========================================================
  // CLEAR USER NOTIFICATIONS
  // =========================================================

  Future<void> clear({required String userId}) {
    return _localCacheService.clearType(
      type: _entityType,
      scope: _scope(userId),
    );
  }

  // =========================================================
  // CACHE STATUS
  // =========================================================

  Future<bool> hasCachedNotifications({required String userId}) {
    return _localCacheService.hasData(type: _entityType, scope: _scope(userId));
  }

  Future<bool> isCacheStale({
    required String userId,
    Duration maxAge = const Duration(minutes: 15),
  }) {
    return _localCacheService.isStale(
      type: _entityType,
      scope: _scope(userId),
      maxAge: maxAge,
    );
  }

  // =========================================================
  // WATCH
  // =========================================================

  Stream<List<MyNotification>> watchNotifications({required String userId}) {
    return _localCacheService
        .watch(type: _entityType, scope: _scope(userId))
        .map((rows) {
          final notifications = <MyNotification>[];

          for (final row in rows) {
            try {
              notifications.add(MyNotification.fromJson(row));
            } catch (_) {
              // Ignore malformed cached data.
            }
          }

          notifications.sort(_sortNotifications);

          return List<MyNotification>.unmodifiable(notifications);
        });
  }

  // =========================================================
  // FILTERING
  // =========================================================

  bool _matchesFilters(
    MyNotification notification, {
    required String type,
    required String priority,
    required bool? isRead,
  }) {
    final json = notification.toJson();

    final normalizedType = type.trim().toLowerCase();

    if (normalizedType.isNotEmpty) {
      final notificationType = (json['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (notificationType != normalizedType) {
        return false;
      }
    }

    final normalizedPriority = priority.trim().toLowerCase();

    if (normalizedPriority.isNotEmpty) {
      final notificationPriority = (json['priority'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (notificationPriority != normalizedPriority) {
        return false;
      }
    }

    if (isRead != null && notification.isRead != isRead) {
      return false;
    }

    return true;
  }

  // =========================================================
  // SEARCH
  // =========================================================

  String _searchableText(MyNotification notification) {
    return [
      notification.title,
      notification.message,
      ..._extraSearchValues(notification.toJson()),
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  String _searchableTextFromJson(Map<String, dynamic> value) {
    return [
      value['title']?.toString() ?? '',
      value['message']?.toString() ?? '',
      value['type']?.toString() ?? '',
      value['priority']?.toString() ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  List<String> _extraSearchValues(Map<String, dynamic> value) {
    return [
      value['type']?.toString() ?? '',
      value['priority']?.toString() ?? '',
    ];
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _metadata(
    MyNotification notification, {
    required bool pendingSync,
  }) {
    final json = notification.toJson();

    return {
      'type': json['type'],
      'priority': json['priority'],
      'isRead': notification.isRead,
      'pendingSync': pendingSync,
      'createdAt': json['created_at'] ?? json['created'],
      'updatedAt': json['updated_at'] ?? json['updated'],
    };
  }

  Map<String, dynamic> _metadataFromJson(Map<String, dynamic> value) {
    return {
      'type': value['type'],
      'priority': value['priority'],
      'isRead': value['is_read'] == true || value['read'] == true,
      'pendingSync': value['pending_sync'] == true,
      'createdAt': value['created_at'] ?? value['created'],
      'updatedAt': value['updated_at'] ?? value['updated'],
    };
  }

  // =========================================================
  // SYNC STATE
  // =========================================================

  Map<String, dynamic> _withSyncState(
    Map<String, dynamic> value, {
    required bool pendingSync,
  }) {
    return {...value, 'pending_sync': pendingSync};
  }

  // =========================================================
  // UPDATED DATE
  // =========================================================

  DateTime? _updatedAt(MyNotification notification) {
    final json = notification.toJson();

    return _dateOrNull(
      json['updated_at'] ??
          json['updated'] ??
          json['created_at'] ??
          json['created'],
    );
  }

  // =========================================================
  // SORTING
  // =========================================================

  int _sortNotifications(MyNotification a, MyNotification b) {
    final aJson = a.toJson();
    final bJson = b.toJson();

    final aDate = _dateOrEpoch(aJson['created_at'] ?? aJson['created']);

    final bDate = _dateOrEpoch(bJson['created_at'] ?? bJson['created']);

    return bDate.compareTo(aDate);
  }

  // =========================================================
  // PAGINATION
  // =========================================================

  List<T> _paginate<T>(
    List<T> items, {
    required int page,
    required int perPage,
  }) {
    final start = (page - 1) * perPage;

    if (start >= items.length) {
      return <T>[];
    }

    final end = (start + perPage).clamp(0, items.length);

    return items.sublist(start, end);
  }

  // =========================================================
  // DATE
  // =========================================================

  DateTime _dateOrEpoch(dynamic value) {
    return _dateOrNull(value) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  DateTime? _dateOrNull(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
