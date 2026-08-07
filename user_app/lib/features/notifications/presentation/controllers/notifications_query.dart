// notifications_query.dart

final class NotificationsQuery {
  const NotificationsQuery({
    this.search = '',
    this.selectedType = '',
    this.selectedPriority = '',
  });

  static const empty = NotificationsQuery();

  final String search;
  final String selectedType;
  final String selectedPriority;

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      selectedType.isNotEmpty ||
      selectedPriority.isNotEmpty;

  NotificationsQuery copyWith({
    String? search,
    String? selectedType,
    String? selectedPriority,
  }) {
    return NotificationsQuery(
      search: search ?? this.search,
      selectedType: selectedType ?? this.selectedType,
      selectedPriority: selectedPriority ?? this.selectedPriority,
    );
  }
}
