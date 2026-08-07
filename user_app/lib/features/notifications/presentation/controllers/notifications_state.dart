// notifications_state.dart

import 'package:user_app/features/notifications/presentation/controllers/notifications_query.dart';

final class NotificationsState {
  const NotificationsState({this.query = NotificationsQuery.empty});

  final NotificationsQuery query;

  String get searchQuery => query.search;

  String get selectedType => query.selectedType;

  String get selectedPriority => query.selectedPriority;

  bool get hasActiveFilters => query.hasActiveFilters;

  NotificationsState copyWith({NotificationsQuery? query}) {
    return NotificationsState(query: query ?? this.query);
  }
}
