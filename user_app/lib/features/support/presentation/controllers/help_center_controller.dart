// help_center_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/support/data/repositories/support_repository.dart';
import 'package:user_app/features/support/presentation/controllers/help_center_query.dart';
import 'package:user_app/features/support/presentation/controllers/help_center_state.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'help_center_controller.g.dart';

@riverpod
class HelpCenterController extends _$HelpCenterController {
  Timer? _searchDebounce;

  late final PagingController<int, SupportTicket> pagingController;

  SupportRepository get _repository => ref.read(supportRepositoryProvider);

  static const List<String> availableCategories = [
    'Technical Issue',
    'Account Problem',
    'Feature Request',
    'Bug Report',
    'General Question',
    'Other',
  ];

  @override
  HelpCenterState build() {
    pagingController = PagingController<int, SupportTicket>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: loadTicketsPage,
    );

    ref.onDispose(() {
      _searchDebounce?.cancel();
      pagingController.dispose();
    });

    return const HelpCenterState();
  }

  // ======================================================
  // TICKETS
  // ======================================================

  Future<List<SupportTicket>> loadTicketsPage(int pageKey) {
    final query = state.query;

    return searchMyTickets(
      query: query.search,
      page: pageKey,
      perPage: AppConstants.pageSize,
      statusFilter: query.statusFilter,
      priorityFilter: query.priorityFilter,
      categoryFilter: query.categoryFilter,
    );
  }

  void refreshTickets() {
    pagingController.refresh();
  }

  // ======================================================
  // CREATE TICKET
  // ======================================================

  Future<bool> createTicket({
    required String subject,
    required String description,
    required String category,
    required TicketPriority priority,
  }) async {
    if (state.isCreatingTicket) {
      return false;
    }

    state = state.copyWith(isCreatingTicket: true, clearErrorMessage: true);

    try {
      await createMyTicket(
        subject: subject,
        description: description,
        category: category,
        priority: priority,
      );

      refreshTickets();

      _showSuccess('Support ticket created successfully');

      return true;
    } catch (error) {
      final message = 'Failed to create ticket: $error';

      state = state.copyWith(errorMessage: message);

      _showError(message);

      return false;
    } finally {
      state = state.copyWith(isCreatingTicket: false);
    }
  }

  // ======================================================
  // DETAILS
  // ======================================================

  Future<void> loadTicketDetails(String ticketId) async {
    state = state.copyWith(
      isLoading: true,
      clearSelectedTicket: true,
      currentTicketReplies: const [],
      clearErrorMessage: true,
    );

    try {
      final ticket = await getMyTicketById(ticketId);

      final replies = await getMyTicketReplies(ticketId: ticketId);

      state = state.copyWith(
        selectedTicket: ticket,
        currentTicketReplies: List<SupportTicketReply>.unmodifiable(replies),
      );
    } catch (error) {
      final message = 'Failed to load ticket details: $error';

      state = state.copyWith(errorMessage: message);

      _showError(message);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ======================================================
  // REPLY
  // ======================================================

  Future<bool> addReplyToCurrentTicket(String message) async {
    final ticket = state.selectedTicket;

    final trimmed = message.trim();

    if (ticket == null || trimmed.isEmpty || state.isAddingReply) {
      return false;
    }

    state = state.copyWith(isAddingReply: true, clearErrorMessage: true);

    try {
      final reply = await addReplyToMyTicket(
        ticketId: ticket.id,
        message: trimmed,
      );

      state = state.copyWith(
        currentTicketReplies: List<SupportTicketReply>.unmodifiable([
          ...state.currentTicketReplies,
          reply,
        ]),
      );

      _showSuccess('Reply added successfully');

      return true;
    } catch (error) {
      final errorMessage = 'Failed to add reply: $error';

      state = state.copyWith(errorMessage: errorMessage);

      _showError(errorMessage);

      return false;
    } finally {
      state = state.copyWith(isAddingReply: false);
    }
  }

  // ======================================================
  // SEARCH
  // ======================================================

  void updateSearchQuery(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    _scheduleSearchRefresh();
  }

  void _scheduleSearchRefresh() {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      AppConstants.searchDebounce,
      pagingController.refresh,
    );
  }

  // ======================================================
  // FILTERS
  // ======================================================

  void updateStatusFilter(String status) {
    state = state.copyWith(query: state.query.copyWith(selectedStatus: status));

    refreshTickets();
  }

  void updatePriorityFilter(String priority) {
    state = state.copyWith(
      query: state.query.copyWith(selectedPriority: priority),
    );

    refreshTickets();
  }

  void updateCategoryFilter(String category) {
    state = state.copyWith(
      query: state.query.copyWith(selectedCategory: category),
    );

    refreshTickets();
  }

  void clearFilters() {
    _searchDebounce?.cancel();

    state = state.copyWith(query: HelpCenterQuery.empty);

    refreshTickets();
  }

  // ======================================================
  // FILTER SHEET
  // ======================================================

  Future<void> showFilterBottomSheet(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final query = state.query;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'Filter Support Tickets',
      fields: [
        FilterField.text(
          'search',
          'Search Tickets',
          hint: 'Search subject or description...',
        ),
        FilterField.dropdown('status', 'Status', const [
          'all',
          'open',
          'inProgress',
          'resolved',
          'closed',
        ]),
        FilterField.dropdown('priority', 'Priority', const [
          'all',
          'low',
          'normal',
          'high',
          'urgent',
        ]),
        FilterField.dropdown('category', 'Category', const [
          'all',
          ...availableCategories,
        ]),
      ],
      initialValues: {
        if (query.search.isNotEmpty) 'search': query.search,
        'status': query.selectedStatus,
        'priority': query.selectedPriority,
        'category': query.selectedCategory,
      },
    );

    if (result == null) {
      return;
    }

    state = state.copyWith(
      query: HelpCenterQuery(
        search: result.getValue<String>('search')?.trim() ?? '',
        selectedStatus: result.getValue<String>('status')?.trim() ?? 'all',
        selectedPriority: result.getValue<String>('priority')?.trim() ?? 'all',
        selectedCategory: result.getValue<String>('category')?.trim() ?? 'all',
      ),
    );

    refreshTickets();
  }

  // ======================================================
  // REPOSITORY WRAPPERS
  // ======================================================

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

  Future<SupportTicket?> getMyTicketById(String ticketId, {String? expand}) {
    return _repository.getTicket(ticketId);
  }

  Future<SupportTicket> createMyTicket({
    required String subject,
    required String description,
    String? category,
    TicketPriority priority = TicketPriority.normal,
  }) {
    return _repository.createTicket(
      subject: subject,
      description: description,
      category: category,
      priority: priority,
    );
  }

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
  }) {
    return _repository.createReply(ticketId: ticketId, message: message);
  }

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
      search: query.trim().isEmpty ? null : query.trim(),
      status: statusFilter,
      priority: priorityFilter,
      category: categoryFilter,
    );

    return result.items;
  }

  // ======================================================
  // MESSAGE HELPERS
  // ======================================================

  void _showSuccess(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.success(context, message);
  }

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }
}
