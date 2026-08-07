// help_center_query.dart

import 'package:user_app/shared/models/models.dart';

final class HelpCenterQuery {
  const HelpCenterQuery({
    this.search = '',
    this.selectedStatus = 'all',
    this.selectedPriority = 'all',
    this.selectedCategory = 'all',
  });

  static const empty = HelpCenterQuery();

  final String search;
  final String selectedStatus;
  final String selectedPriority;
  final String selectedCategory;

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      selectedStatus != 'all' ||
      selectedPriority != 'all' ||
      selectedCategory != 'all';

  TicketStatus? get statusFilter {
    return switch (selectedStatus) {
      'open' => TicketStatus.open,
      'inProgress' => TicketStatus.inProgress,
      'resolved' => TicketStatus.resolved,
      'closed' => TicketStatus.closed,
      _ => null,
    };
  }

  TicketPriority? get priorityFilter {
    return switch (selectedPriority) {
      'low' => TicketPriority.low,
      'normal' => TicketPriority.normal,
      'high' => TicketPriority.high,
      'urgent' => TicketPriority.urgent,
      _ => null,
    };
  }

  String? get categoryFilter =>
      selectedCategory == 'all' ? null : selectedCategory;

  HelpCenterQuery copyWith({
    String? search,
    String? selectedStatus,
    String? selectedPriority,
    String? selectedCategory,
  }) {
    return HelpCenterQuery(
      search: search ?? this.search,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}
