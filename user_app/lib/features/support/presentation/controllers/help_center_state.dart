// help_center_state.dart

import 'package:user_app/features/support/presentation/controllers/help_center_query.dart';
import 'package:user_app/shared/models/models.dart';

final class HelpCenterState {
  const HelpCenterState({
    this.query = HelpCenterQuery.empty,
    this.isLoading = false,
    this.isCreatingTicket = false,
    this.isAddingReply = false,
    this.selectedTicket,
    this.currentTicketReplies = const [],
    this.errorMessage,
  });

  final HelpCenterQuery query;

  final bool isLoading;
  final bool isCreatingTicket;
  final bool isAddingReply;

  final SupportTicket? selectedTicket;
  final List<SupportTicketReply> currentTicketReplies;

  final String? errorMessage;

  bool get hasActiveFilters => query.hasActiveFilters;

  String get searchQuery => query.search;

  String get selectedStatus => query.selectedStatus;

  String get selectedPriority => query.selectedPriority;

  String get selectedCategory => query.selectedCategory;

  HelpCenterState copyWith({
    HelpCenterQuery? query,
    bool? isLoading,
    bool? isCreatingTicket,
    bool? isAddingReply,
    SupportTicket? selectedTicket,
    bool clearSelectedTicket = false,
    List<SupportTicketReply>? currentTicketReplies,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HelpCenterState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      isCreatingTicket: isCreatingTicket ?? this.isCreatingTicket,
      isAddingReply: isAddingReply ?? this.isAddingReply,
      selectedTicket: clearSelectedTicket
          ? null
          : selectedTicket ?? this.selectedTicket,
      currentTicketReplies: currentTicketReplies ?? this.currentTicketReplies,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
