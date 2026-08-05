import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

final class SupportRepository {
  SupportRepository(this._api);

  final BackendApiService _api;

  Future<PagedResult<SupportTicket>> listTickets({
    int page = 1,
    int perPage = 30,
    String? search,
    TicketStatus? status,
    TicketPriority? priority,
    String? category,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/support/tickets',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (_present(search)) 'search': search!.trim(),
        if (status != null) 'status': _status(status),
        if (priority != null) 'priority': priority.name,
        if (_present(category)) 'category': category!.trim(),
        'sort': 'updated_at',
        'order': 'desc',
      },
    );
    return _ticketPage(_data(response), page, perPage);
  }

  Future<SupportTicket> getTicket(String id) async {
    final response = await _api.requestJson(
      '/api/v2/support/tickets/$id',
      method: 'GET',
    );
    return _ticket(_data(response));
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required TicketPriority priority,
    String? category,
  }) async {
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
    return _ticket(_data(response));
  }

  Future<PagedResult<SupportTicketReply>> listReplies(
    String ticketId, {
    int page = 1,
    int perPage = 100,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/support/tickets/$ticketId/replies',
      method: 'GET',
      query: {'page': '$page', 'per_page': '$perPage'},
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _reply(Map<String, dynamic>.from(item)))
        .toList();
    return PagedResult(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<SupportTicketReply> createReply({
    required String ticketId,
    required String message,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/support/tickets/$ticketId/replies',
      method: 'POST',
      body: {'message': message, 'is_internal': false},
    );
    return _reply(_data(response));
  }

  PagedResult<SupportTicket> _ticketPage(
    Map<String, dynamic> data,
    int page,
    int perPage,
  ) {
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _ticket(Map<String, dynamic>.from(item)))
        .toList();
    return PagedResult(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  SupportTicket _ticket(Map<String, dynamic> raw) =>
      SupportTicket(_normalize(raw, SupportTicket.collection));

  SupportTicketReply _reply(Map<String, dynamic> raw) =>
      SupportTicketReply.fromJson(raw);

  Map<String, dynamic> _normalize(Map<String, dynamic> raw, String collection) {
    final data = <String, dynamic>{
      ...raw,
      'collectionName': collection,
      'collectionId': collection,
      'created': raw['created_at']?.toString() ?? '',
      'updated': raw['updated_at']?.toString() ?? '',
    };
    final userId = raw['user_id']?.toString() ?? '';
    if (userId.isNotEmpty) {
      data['expand'] = {
        'user_id': {
          'id': userId,
          'name': raw['user_name']?.toString() ?? '',
          'email': raw['user_email']?.toString() ?? '',
          'collectionName': 'users',
          'collectionId': 'users',
        },
      };
    }
    return data;
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  static String _status(TicketStatus status) => switch (status) {
    TicketStatus.inProgress => 'in_progress',
    _ => status.name,
  };

  static bool _present(String? value) => value?.trim().isNotEmpty == true;
}
