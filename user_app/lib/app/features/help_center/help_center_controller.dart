import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../data/models/models.dart';
import '../../data/repositories/support_repository.dart';
import '../../core/di/core_providers.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import '../../data/models/filter_models.dart';

/// Enhanced Help Center Controller with user-specific support ticket management
final helpCenterControllerProvider = ChangeNotifierProvider.autoDispose((ref) {
  return HelpCenterController(ref.watch(supportRepositoryProvider));
});

class HelpCenterController extends ChangeNotifier {
  HelpCenterController(this._repository) {
    initializePagination();
  }

  final SupportRepository _repository;

  // Reactive state
  bool isLoading = false;
  bool isCreatingTicket = false;
  bool isAddingReply = false;
  String searchQuery = '';
  String selectedStatus = 'all';
  String selectedPriority = 'all';
  String selectedCategory = 'all';

  // Ticket data
  final tickets = <SupportTicket>[];
  SupportTicket? selectedTicket;
  List<SupportTicketReply> currentTicketReplies = [];

  // Infinite scroll pagination
  late PagingController<int, SupportTicket> pagingController;

  // Filter helpers
  bool hasActiveFilters = false;
  Timer? _searchDebounce;
  bool _disposed = false;

  // Available categories for tickets
  final List<String> availableCategories = [
    'Technical Issue',
    'Account Problem',
    'Feature Request',
    'Bug Report',
    'General Question',
    'Other',
  ];

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    pagingController.dispose();
    super.dispose();
  }

  /// Initialize pagination controller
  void initializePagination() {
    pagingController = PagingController<int, SupportTicket>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : (state.keys?.last ?? 0) + 1,
      fetchPage: (pageKey) => loadTicketsPage(pageKey),
    );
  }

  /// Update active filters indicator
  void updateActiveFilters() {
    hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedStatus != 'all' ||
        selectedPriority != 'all' ||
        selectedCategory != 'all';
    if (!_disposed) notifyListeners();
  }

  /// Load tickets page for infinite scroll pagination
  Future<List<SupportTicket>> loadTicketsPage(int pageKey) async {
    return await searchMyTickets(
      query: searchQuery,
      page: pageKey,
      perPage: pageSize,
      statusFilter: getStatusFilter(),
      priorityFilter: getPriorityFilter(),
      categoryFilter: selectedCategory == 'all' ? null : selectedCategory,
    );
  }

  /// Get status filter enum
  TicketStatus? getStatusFilter() {
    if (selectedStatus == 'all') return null;

    switch (selectedStatus) {
      case 'open':
        return TicketStatus.open;
      case 'inProgress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return null;
    }
  }

  /// Get priority filter enum
  TicketPriority? getPriorityFilter() {
    if (selectedPriority == 'all') return null;

    switch (selectedPriority) {
      case 'low':
        return TicketPriority.low;
      case 'normal':
        return TicketPriority.normal;
      case 'high':
        return TicketPriority.high;
      case 'urgent':
        return TicketPriority.urgent;
      default:
        return null;
    }
  }

  /// Refresh tickets list
  void refreshTickets() {
    pagingController.refresh();
  }

  /// Create a new support ticket
  Future<bool> createTicket({
    required String subject,
    required String description,
    required String category,
    required TicketPriority priority,
  }) async {
    try {
      isCreatingTicket = true;
      notifyListeners();

      final ticket = await createMyTicket(
        subject: subject,
        description: description,
        category: category,
        priority: priority,
      );

      tickets.insert(0, ticket);
      refreshTickets();

      Common.quickToast(
        type: ToastificationType.success,
        title: 'Success',
        description: 'Support ticket created successfully',
      );
      return true;
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Error',
        description: 'Failed to create ticket: $e',
      );
      return false;
    } finally {
      isCreatingTicket = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Load ticket details with replies
  Future<void> loadTicketDetails(String ticketId) async {
    try {
      isLoading = true;
      selectedTicket = null;
      currentTicketReplies = [];
      notifyListeners();

      final ticket = await getMyTicketById(ticketId);
      selectedTicket = ticket;

      final replies = await getMyTicketReplies(ticketId: ticketId);
      currentTicketReplies = replies;
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Error',
        description: 'Failed to load ticket details: $e',
      );
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Add reply to current ticket
  Future<bool> addReplyToCurrentTicket(String message) async {
    final ticket = selectedTicket;
    if (ticket == null) return false;

    try {
      isAddingReply = true;
      notifyListeners();

      final reply = await addReplyToMyTicket(
        ticketId: ticket.id,
        message: message,
      );

      currentTicketReplies.add(reply);

      Common.quickToast(
        type: ToastificationType.success,
        title: 'Success',
        description: 'Reply added successfully',
      );
      return true;
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Error',
        description: 'Failed to add reply: $e',
      );
      return false;
    } finally {
      isAddingReply = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Update search query and refresh
  void updateSearchQuery(String query) {
    searchQuery = query;
    updateActiveFilters();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      pagingController.refresh,
    );
  }

  /// Update status filter and refresh
  void updateStatusFilter(String status) {
    selectedStatus = status;
    updateActiveFilters();
    refreshTickets();
  }

  /// Update priority filter and refresh
  void updatePriorityFilter(String priority) {
    selectedPriority = priority;
    updateActiveFilters();
    refreshTickets();
  }

  void updateCategoryFilter(String category) {
    selectedCategory = category;
    updateActiveFilters();
    refreshTickets();
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery = '';
    selectedStatus = 'all';
    selectedPriority = 'all';
    selectedCategory = 'all';
    updateActiveFilters();
    refreshTickets();
  }

  /// Show filter bottom sheet for support tickets
  Future<void> showFilterBottomSheet(BuildContext context) async {
    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'Filter Support Tickets',
      fields: [
        FilterField.text(
          'search',
          'Search Tickets',
          hint: 'Search subject or description...',
        ),
        FilterField.dropdown('status', 'Status', [
          'all',
          'open',
          'inProgress',
          'resolved',
          'closed',
        ]),
        FilterField.dropdown('priority', 'Priority', [
          'all',
          'low',
          'normal',
          'high',
          'urgent',
        ]),
        FilterField.dropdown('category', 'Category', [
          'all',
          ...availableCategories,
        ]),
      ],
      initialValues: {
        'search': searchQuery,
        'status': selectedStatus,
        'priority': selectedPriority,
        'category': selectedCategory,
      },
    );

    if (result != null && result.hasValues) {
      final filters = result.toJson();

      // Apply search query
      if (filters['search'] != null) {
        updateSearchQuery(filters['search'] as String);
      }

      // Apply status filter
      if (filters['status'] != null) {
        updateStatusFilter(filters['status'] as String);
      }

      // Apply priority filter
      if (filters['priority'] != null) {
        updatePriorityFilter(filters['priority'] as String);
      }

      if (filters['category'] != null) {
        updateCategoryFilter(filters['category'] as String);
      }
    }
  }

  // Ownership is enforced by the typed backend using JWT claims.
  Future<List<SupportTicket>> getMyTickets({
    int page = 1,
    int perPage = 30,
    String? additionalFilter,
    String? sort,
    String? expand,
  }) async {
    final result = await _repository.listTickets(page: page, perPage: perPage);
    return result.items;
  }

  Future<SupportTicket?> getMyTicketById(String ticketId, {String? expand}) =>
      _repository.getTicket(ticketId);

  Future<SupportTicket> createMyTicket({
    required String subject,
    required String description,
    String? category,
    TicketPriority priority = TicketPriority.normal,
  }) => _repository.createTicket(
    subject: subject,
    description: description,
    category: category,
    priority: priority,
  );

  Future<List<SupportTicketReply>> getMyTicketReplies({
    required String ticketId,
    int page = 1,
    int perPage = 50,
    String? sort,
  }) async {
    final result = await _repository.listReplies(
      ticketId,
      page: page,
      perPage: perPage,
    );
    return result.items;
  }

  Future<SupportTicketReply> addReplyToMyTicket({
    required String ticketId,
    required String message,
  }) => _repository.createReply(ticketId: ticketId, message: message);

  Future<List<SupportTicket>> searchMyTickets({
    required String query,
    int page = 1,
    int perPage = 30,
    TicketStatus? statusFilter,
    TicketPriority? priorityFilter,
    String? categoryFilter,
  }) async {
    final result = await _repository.listTickets(
      page: page,
      perPage: perPage,
      search: query,
      status: statusFilter,
      priority: priorityFilter,
      category: categoryFilter,
    );
    return result.items;
  }
}
