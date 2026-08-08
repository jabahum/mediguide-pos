import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/shared/models/models.dart';

final supportLocalRepositoryProvider = Provider<SupportLocalRepository>((ref) {
  return SupportLocalRepository(ref.watch(localCacheServiceProvider));
});

final class SupportLocalRepository {
  SupportLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _ticketType = 'support_ticket';
  static const String _replyType = 'support_ticket_reply';

  String _scope(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id is required');
    }

    return 'user:$normalized';
  }

  // =========================================================
  // TICKETS - SAVE
  // =========================================================

  Future<void> saveTicket({
    required String userId,
    required SupportTicket ticket,
    bool pendingSync = false,
  }) async {
    final json = {...ticket.toJson(), 'pending_sync': pendingSync};

    await _localCacheService.put(
      type: _ticketType,
      id: ticket.id,
      scope: _scope(userId),
      data: json,
      searchableText: _ticketSearchableText(json),
      metadata: _ticketMetadata(json),
      remoteUpdatedAt: _updatedAt(json),
    );
  }

  Future<void> saveTickets({
    required String userId,
    required Iterable<SupportTicket> tickets,
  }) async {
    if (tickets.isEmpty) return;

    await _localCacheService.putMany(
      type: _ticketType,
      scope: _scope(userId),
      entities: tickets.map((ticket) {
        final json = {...ticket.toJson(), 'pending_sync': false};

        return CachedEntityInput(
          id: ticket.id,
          data: json,
          searchableText: _ticketSearchableText(json),
          metadata: _ticketMetadata(json),
          remoteUpdatedAt: _updatedAt(json),
        );
      }),
    );
  }

  // =========================================================
  // TICKETS - GET
  // =========================================================

  Future<SupportTicket?> getTicket({
    required String userId,
    required String ticketId,
  }) async {
    final row = await _localCacheService.get(
      type: _ticketType,
      id: ticketId,
      scope: _scope(userId),
    );

    if (row == null) return null;

    try {
      return SupportTicket.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTicketRecord({
    required String userId,
    required String ticketId,
  }) {
    return _localCacheService.get(
      type: _ticketType,
      id: ticketId,
      scope: _scope(userId),
    );
  }

  Future<List<SupportTicket>> getTickets({
    required String userId,
    int page = 1,
    int perPage = 30,
    String search = '',
    TicketStatus? status,
    TicketPriority? priority,
    String category = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    final rows = await _localCacheService.list(
      type: _ticketType,
      scope: _scope(userId),
      search: search.trim(),
      limit: 1000,
      offset: 0,
    );

    final tickets = <SupportTicket>[];

    for (final row in rows) {
      try {
        final ticket = SupportTicket.fromJson(row);

        if (!_matchesTicketFilters(
          ticket,
          status: status,
          priority: priority,
          category: category,
        )) {
          continue;
        }

        tickets.add(ticket);
      } catch (_) {}
    }

    tickets.sort(_sortTickets);

    return _paginate(tickets, page: safePage, perPage: safePerPage);
  }

  // =========================================================
  // REPLIES - SAVE
  // =========================================================

  Future<void> saveReply({
    required String userId,
    required String ticketId,
    required SupportTicketReply reply,
    bool pendingSync = false,
  }) async {
    final json = {
      ...reply.toJson(),
      'ticket_id': ticketId,
      'pending_sync': pendingSync,
    };

    await _localCacheService.put(
      type: _replyType,
      id: reply.id,
      scope: _scope(userId),
      data: json,
      searchableText: (json['message'] ?? '').toString().toLowerCase(),
      metadata: {
        'ticketId': ticketId,
        'pendingSync': pendingSync,
        'createdAt': json['created_at'] ?? json['created'],
      },
      remoteUpdatedAt: _updatedAt(json),
    );
  }

  Future<void> saveReplies({
    required String userId,
    required String ticketId,
    required Iterable<SupportTicketReply> replies,
  }) async {
    if (replies.isEmpty) return;

    await _localCacheService.putMany(
      type: _replyType,
      scope: _scope(userId),
      entities: replies.map((reply) {
        final json = {
          ...reply.toJson(),
          'ticket_id': ticketId,
          'pending_sync': false,
        };

        return CachedEntityInput(
          id: reply.id,
          data: json,
          searchableText: (json['message'] ?? '').toString().toLowerCase(),
          metadata: {
            'ticketId': ticketId,
            'pendingSync': false,
            'createdAt': json['created_at'] ?? json['created'],
          },
          remoteUpdatedAt: _updatedAt(json),
        );
      }),
    );
  }

  // =========================================================
  // REPLIES - GET
  // =========================================================

  Future<List<SupportTicketReply>> getReplies({
    required String userId,
    required String ticketId,
    int page = 1,
    int perPage = 100,
  }) async {
    final rows = await _localCacheService.list(
      type: _replyType,
      scope: _scope(userId),
      limit: 1000,
      offset: 0,
    );

    final replies = <SupportTicketReply>[];

    for (final row in rows) {
      if ((row['ticket_id'] ?? '').toString() != ticketId) {
        continue;
      }

      try {
        replies.add(SupportTicketReply.fromJson(row));
      } catch (_) {}
    }

    replies.sort(_sortReplies);

    return _paginate(replies, page: page, perPage: perPage);
  }

  // =========================================================
  // PENDING
  // =========================================================

  Future<List<Map<String, dynamic>>> pendingTickets({
    required String userId,
  }) async {
    final rows = await _localCacheService.list(
      type: _ticketType,
      scope: _scope(userId),
      limit: 1000,
      offset: 0,
    );

    return rows
        .where((row) => row['pending_sync'] == true)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> pendingReplies({
    required String userId,
  }) async {
    final rows = await _localCacheService.list(
      type: _replyType,
      scope: _scope(userId),
      limit: 1000,
      offset: 0,
    );

    return rows
        .where((row) => row['pending_sync'] == true)
        .toList(growable: false);
  }

  // =========================================================
  // REMOVE LOCAL TEMP RECORDS
  // =========================================================

  Future<void> removeTicket({
    required String userId,
    required String ticketId,
  }) {
    return _localCacheService.remove(
      type: _ticketType,
      id: ticketId,
      scope: _scope(userId),
    );
  }

  Future<void> removeReply({required String userId, required String replyId}) {
    return _localCacheService.remove(
      type: _replyType,
      id: replyId,
      scope: _scope(userId),
    );
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedTickets({required String userId}) {
    return _localCacheService.hasData(type: _ticketType, scope: _scope(userId));
  }

  Future<void> clear({required String userId}) async {
    await Future.wait([
      _localCacheService.clearType(type: _ticketType, scope: _scope(userId)),
      _localCacheService.clearType(type: _replyType, scope: _scope(userId)),
    ]);
  }

  // =========================================================
  // FILTERS
  // =========================================================

  bool _matchesTicketFilters(
    SupportTicket ticket, {
    required TicketStatus? status,
    required TicketPriority? priority,
    required String category,
  }) {
    if (status != null && ticket.status != status) {
      return false;
    }

    if (priority != null && ticket.priority != priority) {
      return false;
    }

    final normalizedCategory = category.trim().toLowerCase();

    if (normalizedCategory.isNotEmpty &&
        ticket.category.trim().toLowerCase() != normalizedCategory) {
      return false;
    }

    return true;
  }

  // =========================================================
  // SEARCH / METADATA
  // =========================================================

  String _ticketSearchableText(Map<String, dynamic> json) {
    return [
      json['subject']?.toString() ?? '',
      json['description']?.toString() ?? '',
      json['category']?.toString() ?? '',
      json['status']?.toString() ?? '',
      json['priority']?.toString() ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  Map<String, dynamic> _ticketMetadata(Map<String, dynamic> json) {
    return {
      'status': json['status'],
      'priority': json['priority'],
      'category': json['category'],
      'pendingSync': json['pending_sync'] == true,
      'updatedAt': json['updated_at'] ?? json['updated'],
    };
  }

  // =========================================================
  // SORTING
  // =========================================================

  int _sortTickets(SupportTicket a, SupportTicket b) {
    final aDate =
        _updatedAt(a.toJson()) ?? DateTime.fromMillisecondsSinceEpoch(0);

    final bDate =
        _updatedAt(b.toJson()) ?? DateTime.fromMillisecondsSinceEpoch(0);

    return bDate.compareTo(aDate);
  }

  int _sortReplies(SupportTicketReply a, SupportTicketReply b) {
    final aDate =
        _createdAt(a.toJson()) ?? DateTime.fromMillisecondsSinceEpoch(0);

    final bDate =
        _createdAt(b.toJson()) ?? DateTime.fromMillisecondsSinceEpoch(0);

    return aDate.compareTo(bDate);
  }

  // =========================================================
  // HELPERS
  // =========================================================

  List<T> _paginate<T>(
    List<T> items, {
    required int page,
    required int perPage,
  }) {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    final start = (safePage - 1) * safePerPage;

    if (start >= items.length) {
      return <T>[];
    }

    final end = (start + safePerPage).clamp(0, items.length);

    return items.sublist(start, end);
  }

  DateTime? _updatedAt(Map<String, dynamic> json) {
    return _date(
      json['updated_at'] ??
          json['updated'] ??
          json['created_at'] ??
          json['created'],
    );
  }

  DateTime? _createdAt(Map<String, dynamic> json) {
    return _date(json['created_at'] ?? json['created']);
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }
}
