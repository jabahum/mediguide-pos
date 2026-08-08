import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

import 'package:user_app/features/support/data/repositories/support_local_repository.dart';

final class SupportRepository {
  SupportRepository(this._api, this._local, {required this.userId});

  final BackendApiService _api;
  final SupportLocalRepository _local;
  final String userId;

  // =========================================================
  // LIST TICKETS
  // =========================================================

  Future<PaginatedResponse<SupportTicket>> listTickets({
    int page = 1,
    int perPage = 30,
    String? search,
    TicketStatus? status,
    TicketPriority? priority,
    String? category,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    await syncPending();

    try {
      final response = await _api.requestJson(
        '/api/v2/support/tickets',
        method: 'GET',
        query: {
          'page': '$safePage',
          'per_page': '$safePerPage',
          if (_present(search)) 'search': search!.trim(),
          if (status != null) 'status': _status(status),
          if (priority != null) 'priority': priority.name,
          if (_present(category)) 'category': category!.trim(),
          'sort': 'updated_at',
          'order': 'desc',
        },
      );

      final result = _ticketPage(_data(response), safePage, safePerPage);

      try {
        await _local.saveTickets(userId: userId, tickets: result.items);
      } catch (_) {}

      return result;
    } catch (_) {
      final cached = await _local.getTickets(
        userId: userId,
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        status: status,
        priority: priority,
        category: category ?? '',
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<SupportTicket>(
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: _totalPages(cached.length, safePerPage),
        items: cached,
      );
    }
  }

  // =========================================================
  // GET TICKET
  // =========================================================

  Future<SupportTicket?> getTicket(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    try {
      final response = await _api.requestJson(
        '/api/v2/support/tickets/${Uri.encodeComponent(normalizedId)}',
        method: 'GET',
      );

      final ticket = _ticket(_data(response));

      try {
        await _local.saveTicket(userId: userId, ticket: ticket);
      } catch (_) {}

      return ticket;
    } catch (_) {
      return _local.getTicket(userId: userId, ticketId: normalizedId);
    }
  }

  // =========================================================
  // CREATE TICKET
  // =========================================================

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required TicketPriority priority,
    String? category,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final localId = 'local-ticket-${DateTime.now().microsecondsSinceEpoch}';

    final optimistic = SupportTicket.fromJson({
      'id': localId,
      'subject': subject,
      'description': description,
      'priority': priority.name,
      'status': 'open',
      'category': category?.trim() ?? '',
      'created_at': now,
      'updated_at': now,
      'pending_sync': true,
    });

    await _local.saveTicket(
      userId: userId,
      ticket: optimistic,
      pendingSync: true,
    );

    try {
      final response = await _api.requestJson(
        '/api/v2/support/tickets',
        method: 'POST',
        body: {
          'subject': subject,
          'description': description,
          'priority': priority.name,
          if (_present(category)) 'category': category!.trim(),
        },
      );

      final remote = _ticket(_data(response));

      await _local.removeTicket(userId: userId, ticketId: localId);

      await _local.saveTicket(
        userId: userId,
        ticket: remote,
        pendingSync: false,
      );

      return remote;
    } catch (_) {
      return optimistic;
    }
  }

  // =========================================================
  // LIST REPLIES
  // =========================================================

  Future<PaginatedResponse<SupportTicketReply>> listReplies(
    String ticketId, {
    int page = 1,
    int perPage = 100,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    try {
      final response = await _api.requestJson(
        '/api/v2/support/tickets/${Uri.encodeComponent(ticketId)}/replies',
        method: 'GET',
        query: {'page': '$safePage', 'per_page': '$safePerPage'},
      );

      final data = _data(response);

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _reply(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      try {
        await _local.saveReplies(
          userId: userId,
          ticketId: ticketId,
          replies: items,
        );
      } catch (_) {}

      return PaginatedResponse<SupportTicketReply>(
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
        items: items,
      );
    } catch (_) {
      final cached = await _local.getReplies(
        userId: userId,
        ticketId: ticketId,
        page: safePage,
        perPage: safePerPage,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<SupportTicketReply>(
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: _totalPages(cached.length, safePerPage),
        items: cached,
      );
    }
  }

  // =========================================================
  // CREATE REPLY
  // =========================================================

  Future<SupportTicketReply> createReply({
    required String ticketId,
    required String message,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final localId = 'local-reply-${DateTime.now().microsecondsSinceEpoch}';

    final optimistic = SupportTicketReply.fromJson({
      'id': localId,
      'ticket_id': ticketId,
      'message': message,
      'is_internal': false,
      'created_at': now,
      'updated_at': now,
      'pending_sync': true,
    });

    await _local.saveReply(
      userId: userId,
      ticketId: ticketId,
      reply: optimistic,
      pendingSync: true,
    );

    try {
      final response = await _api.requestJson(
        '/api/v2/support/tickets/${Uri.encodeComponent(ticketId)}/replies',
        method: 'POST',
        body: {'message': message, 'is_internal': false},
      );

      final remote = _reply(_data(response));

      await _local.removeReply(userId: userId, replyId: localId);

      await _local.saveReply(
        userId: userId,
        ticketId: ticketId,
        reply: remote,
        pendingSync: false,
      );

      return remote;
    } catch (_) {
      return optimistic;
    }
  }

  // =========================================================
  // SYNC PENDING
  // =========================================================

  Future<void> syncPending() async {
    if (userId.trim().isEmpty) return;

    await _syncPendingTickets();
    await _syncPendingReplies();
  }

  Future<void> _syncPendingTickets() async {
    final pending = await _local.pendingTickets(userId: userId);

    for (final record in pending) {
      final localId = record['id']?.toString() ?? '';

      try {
        final response = await _api.requestJson(
          '/api/v2/support/tickets',
          method: 'POST',
          body: {
            'subject': record['subject'],
            'description': record['description'],
            'priority': record['priority'],
            if (_present(record['category']?.toString()))
              'category': record['category'].toString().trim(),
          },
        );

        final remote = _ticket(_data(response));

        await _local.removeTicket(userId: userId, ticketId: localId);

        await _local.saveTicket(
          userId: userId,
          ticket: remote,
          pendingSync: false,
        );
      } catch (_) {
        // Retry later.
      }
    }
  }

  Future<void> _syncPendingReplies() async {
    final pending = await _local.pendingReplies(userId: userId);

    for (final record in pending) {
      final localId = record['id']?.toString() ?? '';

      final ticketId = record['ticket_id']?.toString() ?? '';

      if (ticketId.isEmpty) continue;

      //
      // If the reply belongs to a locally-created ticket that has
      // not yet received a remote ID, it cannot be synchronized yet.
      //
      if (ticketId.startsWith('local-ticket-')) {
        continue;
      }

      try {
        final response = await _api.requestJson(
          '/api/v2/support/tickets/${Uri.encodeComponent(ticketId)}/replies',
          method: 'POST',
          body: {'message': record['message'], 'is_internal': false},
        );

        final remote = _reply(_data(response));

        await _local.removeReply(userId: userId, replyId: localId);

        await _local.saveReply(
          userId: userId,
          ticketId: ticketId,
          reply: remote,
          pendingSync: false,
        );
      } catch (_) {
        // Retry later.
      }
    }
  }

  // =========================================================
  // PAGE PARSING
  // =========================================================

  PaginatedResponse<SupportTicket> _ticketPage(
    Map<String, dynamic> data,
    int page,
    int perPage,
  ) {
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _ticket(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return PaginatedResponse<SupportTicket>(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages:
          (data['total_pages'] as num?)?.toInt() ??
          _totalPages(items.length, perPage),
      items: items,
    );
  }

  // =========================================================
  // MODELS
  // =========================================================

  SupportTicket _ticket(Map<String, dynamic> raw) {
    return SupportTicket.fromJson(raw);
  }

  SupportTicketReply _reply(Map<String, dynamic> raw) {
    return SupportTicketReply.fromJson(raw);
  }

  // =========================================================
  // RESPONSE
  // =========================================================

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];

    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  static String _status(TicketStatus status) {
    return switch (status) {
      TicketStatus.inProgress => 'in_progress',
      _ => status.name,
    };
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
