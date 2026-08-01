import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../data/models/models.dart';
import '../../data/repositories/support_repository.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import '../../data/models/filter_models.dart';

/// Enhanced Help Center Controller with user-specific support ticket management
class HelpCenterController extends GetxController {
  SupportRepository get _repository => SupportRepository(BackendApiService.to);

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
  }

  @override
  void onClose() {
    pagingController.dispose();
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

  /// Load tickets page for infinite scroll pagination
  Future<List<SupportTicket>> loadTicketsPage(int pageKey) async {
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
