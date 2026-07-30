import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../data/models/models.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import '../../data/models/filter_models.dart';

/// Enhanced Help Center Controller with user-specific support ticket management
class HelpCenterController extends GetxController {
  // Reactive state
  final isLoading = false.obs;
  final isCreatingTicket = false.obs;
  final isAddingReply = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;
  final selectedPriority = 'all'.obs;

  // Ticket data
  final tickets = <SupportTicket>[].obs;
  final selectedTicket = Rx<SupportTicket?>(null);
  final currentTicketReplies = <SupportTicketReply>[].obs;

  // Infinite scroll pagination
  late PagingController<int, SupportTicket> pagingController;

  // Filter helpers
  final hasActiveFilters = false.obs;

  // Available categories for tickets
  final List<String> availableCategories = [
    'Technical Issue',
    'Account Problem',
    'Feature Request',
    'Bug Report',
    'General Question',
    'Other',
  ];

  // Create ticket form state
  final formKey = GlobalKey<FormBuilderState>();

  // Reply form state
  final replyFormKey = GlobalKey<FormBuilderState>();

  @override
  void onInit() {
    super.onInit();
    initializePagination();
    setupSearchListener();
    subscribeToRealTimeUpdates();
  }

  @override
  void onClose() {
    pagingController.dispose();
    BackendApiService.to.unsubscribeFromCollection(
      collectionName: 'support_tickets',
    );
    BackendApiService.to.unsubscribeFromCollection(
      collectionName: 'support_ticket_replies',
    );
    super.onClose();
  }

  /// Initialize pagination controller
  void initializePagination() {
    pagingController = PagingController<int, SupportTicket>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : (state.keys?.last ?? 0) + 1,
      fetchPage: (pageKey) => loadTicketsPage(pageKey),
    );
  }

  /// Setup search query listener with debouncing
  void setupSearchListener() {
    debounce(
      searchQuery,
      (_) => pagingController.refresh(),
      time: const Duration(milliseconds: 500),
    );

    // Update hasActiveFilters when search or filters change
    ever(searchQuery, (_) => updateActiveFilters());
    ever(selectedStatus, (_) => updateActiveFilters());
    ever(selectedPriority, (_) => updateActiveFilters());
  }

  /// Update active filters indicator
  void updateActiveFilters() {
    hasActiveFilters.value =
        searchQuery.value.isNotEmpty ||
        selectedStatus.value != 'all' ||
        selectedPriority.value != 'all';
  }

  /// Subscribe to real-time updates for user's tickets
  void subscribeToRealTimeUpdates() {
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser != null) {
      subscribeToMyTickets((ticket) {
        pagingController.refresh();
        if (selectedTicket.value?.id == ticket.id) {
          selectedTicket.value = ticket;
        }
      });

      subscribeToMyTicketReplies((reply) {
        if (selectedTicket.value?.id == reply.ticketId) {
          currentTicketReplies.add(reply);
        }
      });
    }
  }

  /// Load tickets page for infinite scroll pagination
  Future<List<SupportTicket>> loadTicketsPage(int pageKey) async {
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('Please log in to view support tickets');
    }

    return await searchMyTickets(
      query: searchQuery.value,
      page: pageKey,
      perPage: pageSize,
      statusFilter: getStatusFilter(),
      priorityFilter: getPriorityFilter(),
    );
  }

  /// Get status filter enum
  TicketStatus? getStatusFilter() {
    if (selectedStatus.value == 'all') return null;

    switch (selectedStatus.value) {
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
    if (selectedPriority.value == 'all') return null;

    switch (selectedPriority.value) {
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

  /// Submit create ticket form
  Future<void> submitCreateTicketForm() async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;

      await createTicket(
        subject: formData['subject'] as String,
        description: formData['description'] as String,
        category: formData['category'] as String,
        priority: formData['priority'] as TicketPriority,
      );

      // Clear form on success
      if (!isCreatingTicket.value) {
        formKey.currentState?.reset();
        Get.back(); // Close dialog
      }
    }
  }

  /// Create a new support ticket
  Future<void> createTicket({
    required String subject,
    required String description,
    required String category,
    required TicketPriority priority,
  }) async {
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Error',
        description: 'Please log in to create a support ticket',
      );
      return;
    }

    try {
      isCreatingTicket.value = true;

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
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Error',
        description: 'Failed to create ticket: $e',
      );
    } finally {
      isCreatingTicket.value = false;
    }
  }

  /// Load ticket details with replies
  Future<void> loadTicketDetails(String ticketId) async {
    try {
      isLoading.value = true;

      final ticket = await getMyTicketById(ticketId);
      selectedTicket.value = ticket;

      final replies = await getMyTicketReplies(ticketId: ticketId);
      currentTicketReplies.value = replies;
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Error',
        description: 'Failed to load ticket details: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Add reply to current ticket
  Future<void> addReplyToCurrentTicket(String message) async {
    final ticket = selectedTicket.value;
    if (ticket == null) return;

    try {
      isAddingReply.value = true;

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
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: 'Error',
        description: 'Failed to add reply: $e',
      );
    } finally {
      isAddingReply.value = false;
    }
  }

  /// Update search query and refresh
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Update status filter and refresh
  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    refreshTickets();
  }

  /// Update priority filter and refresh
  void updatePriorityFilter(String priority) {
    selectedPriority.value = priority;
    refreshTickets();
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    selectedStatus.value = 'all';
    selectedPriority.value = 'all';
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
        'search': searchQuery.value,
        'status': selectedStatus.value,
        'priority': selectedPriority.value,
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

      // Note: Category filtering would need to be implemented in the search method
      // if (filters['category'] != null) {
      //   updateCategoryFilter(filters['category'] as String);
      // }
    }
  }

  // ==================== USER-SPECIFIC SUPPORT TICKET METHODS ====================

  /// Get current user's support tickets only
  /// All queries are automatically filtered by the authenticated user's ID
  Future<List<SupportTicket>> getMyTickets({
    int page = 1,
    int perPage = 30,
    String? additionalFilter,
    String? sort,
    String? expand,
  }) async {
    // Get current authenticated user
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('User must be authenticated to view tickets');
    }

    // Build user-specific filter
    final List<String> filters = ['user_id = "${currentUser.id}"'];

    // Add any additional filters
    if (additionalFilter != null && additionalFilter.isNotEmpty) {
      filters.add(additionalFilter);
    }

    final combinedFilter = filters.join(' && ');

    final result = await BackendApiService.to.getRecordList(
      collectionName: 'support_tickets',
      page: page,
      perPage: perPage,
      filter: combinedFilter,
      sort: sort ?? '-updated',
      expand: expand ?? 'user_id',
    );

    return result.items
        .map((record) => SupportTicket.fromRecord(record))
        .toList();
  }

  /// Get a specific ticket by ID (only if it belongs to current user)
  Future<SupportTicket?> getMyTicketById(
    String ticketId, {
    String? expand,
  }) async {
    // Get current authenticated user
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('User must be authenticated to view ticket');
    }

    try {
      final record = await BackendApiService.to.getRecord(
        collectionName: 'support_tickets',
        recordId: ticketId,
        expand: expand ?? 'user_id',
      );

      if (record == null) return null;

      final ticket = SupportTicket.fromRecord(record);

      // Verify ticket belongs to current user
      if (!ticket.isOwnedBy(currentUser.id)) {
        throw Exception(
          'Access denied: Ticket does not belong to current user',
        );
      }

      return ticket;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new support ticket for the current user
  Future<SupportTicket> createMyTicket({
    required String subject,
    required String description,
    String? category,
    TicketPriority priority = TicketPriority.normal,
  }) async {
    // Get current authenticated user
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('User must be authenticated to create ticket');
    }

    final ticketData = {
      'subject': subject,
      'description': description,
      'category': category ?? '',
      'status': 'open',
      'priority': priority.name,
      'user_id': currentUser.id,
    };

    final record = await BackendApiService.to.createRecord(
      collectionName: 'support_tickets',
      data: ticketData,
    );

    return SupportTicket.fromRecord(record);
  }

  /// Get replies for a specific ticket (only if ticket belongs to current user)
  /// Excludes internal replies (is_internal = false only)
  Future<List<SupportTicketReply>> getMyTicketReplies({
    required String ticketId,
    int page = 1,
    int perPage = 50,
    String? sort,
  }) async {
    // First verify the ticket belongs to current user
    await getMyTicketById(ticketId);

    // Get replies for this ticket (exclude internal replies)
    final result = await BackendApiService.to.getRecordList(
      collectionName: 'support_ticket_replies',
      page: page,
      perPage: perPage,
      filter: 'ticket_id = "$ticketId" && is_internal = false',
      sort: sort ?? 'created',
      expand: 'user_id',
    );

    return result.items
        .map((record) => SupportTicketReply.fromRecord(record))
        .toList();
  }

  /// Add a reply to user's own ticket
  Future<SupportTicketReply> addReplyToMyTicket({
    required String ticketId,
    required String message,
  }) async {
    // Get current authenticated user
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('User must be authenticated to reply to ticket');
    }

    // Verify ticket belongs to current user
    await getMyTicketById(ticketId);

    final replyData = {
      'ticket_id': ticketId,
      'message': message,
      'user_id': currentUser.id,
      'is_internal': false, // User replies are always public
    };

    final record = await BackendApiService.to.createRecord(
      collectionName: 'support_ticket_replies',
      data: replyData,
    );

    return SupportTicketReply.fromRecord(record);
  }

  /// Search current user's tickets
  Future<List<SupportTicket>> searchMyTickets({
    required String query,
    int page = 1,
    int perPage = 30,
    TicketStatus? statusFilter,
    TicketPriority? priorityFilter,
    String? categoryFilter,
  }) async {
    // Get current authenticated user
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('User must be authenticated to search tickets');
    }

    final List<String> filters = ['user_id = "${currentUser.id}"'];

    // Search in subject and description
    if (query.isNotEmpty) {
      final q = BackendApiService.escapeFilterValue(query);
      filters.add('(subject ~ "$q" || description ~ "$q")');
    }

    // Status filter
    if (statusFilter != null) {
      filters.add('status = "${statusFilter.name}"');
    }

    // Priority filter
    if (priorityFilter != null) {
      filters.add('priority = "${priorityFilter.name}"');
    }

    // Category filter
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      final category = BackendApiService.escapeFilterValue(categoryFilter);
      filters.add('category = "$category"');
    }

    final combinedFilter = filters.join(' && ');

    final result = await BackendApiService.to.getRecordList(
      collectionName: 'support_tickets',
      page: page,
      perPage: perPage,
      filter: combinedFilter,
      sort: '-updated',
      expand: 'user_id',
    );

    return result.items
        .map((record) => SupportTicket.fromRecord(record))
        .toList();
  }

  /// Subscribe to real-time updates for current user's tickets
  void subscribeToMyTickets(Function(SupportTicket) onTicketUpdate) {
    // Get current authenticated user
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('User must be authenticated to subscribe to tickets');
    }

    BackendApiService.to.subscribeToCollection('support_tickets', (event) {
      if (event.record != null) {
        final ticket = SupportTicket.fromRecord(event.record!);
        // Only notify if ticket belongs to current user
        if (ticket.isOwnedBy(currentUser.id)) {
          onTicketUpdate(ticket);
        }
      }
    }, filter: 'user_id = "${currentUser.id}"');
  }

  /// Subscribe to real-time updates for replies to current user's tickets
  void subscribeToMyTicketReplies(Function(SupportTicketReply) onReplyUpdate) {
    // Get current authenticated user
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('User must be authenticated to subscribe to replies');
    }

    BackendApiService.to.subscribeToCollection('support_ticket_replies', (
      event,
    ) {
      if (event.record != null) {
        final reply = SupportTicketReply.fromRecord(event.record!);
        // Only show public replies (is_internal = false)
        if (reply.isPublic) {
          onReplyUpdate(reply);
        }
      }
    }, filter: 'is_internal = false');
  }
}
