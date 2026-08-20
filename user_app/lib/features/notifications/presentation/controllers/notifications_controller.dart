// notifications_controller.dart

import 'dart:async';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:user_app/features/notifications/presentation/controllers/notifications_query.dart';
import 'package:user_app/features/notifications/presentation/controllers/notifications_state.dart';

import 'package:user_app/shared/models/models.dart';

part 'notifications_controller.g.dart';

@riverpod
class NotificationsController extends _$NotificationsController {
  Timer? _debounce;

  late final PagingController<int, MyNotification> pagingController;

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  NotificationsState build() {
    pagingController = PagingController<int, MyNotification>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: _loadPage,
    );

    ref.onDispose(() {
      _debounce?.cancel();
      pagingController.dispose();
    });

    return const NotificationsState();
  }

  // ======================================================
  // DATA LOADING
  // ======================================================

  Future<List<MyNotification>> _loadPage(int pageKey) async {
    try {
      final query = state.query;

      final result = await _repository.list(
        page: pageKey,
        perPage: AppConstants.pageSize,
        search: query.search.isEmpty ? null : query.search,
        type: query.selectedType.isEmpty ? null : query.selectedType,
        priority: query.selectedPriority.isEmpty
            ? null
            : query.selectedPriority,
      );

      return result.items;
    } catch (error) {
      _showError('Error loading notifications $error');

      rethrow;
    }
  }

  // ======================================================
  // MARK READ
  // ======================================================

  Future<void> markRead(MyNotification notification) async {
    if (notification.isRead) {
      return;
    }

    try {
      await _repository.markRead(notification.id);

      pagingController.refresh();
    } catch (error) {
      _showError('Failed to mark notification as read: $error');
    }
  }

  Future<void> recordOpen(MyNotification notification) async {
    final deliveryId = notification.deliveryId?.trim();
    if (deliveryId == null || deliveryId.isEmpty) return;
    await _repository.recordOpen(
      deliveryId,
      eventId: 'in-app-open-${notification.id}',
    );
  }

  Future<void> recordClick(MyNotification notification) async {
    final deliveryId = notification.deliveryId?.trim();
    if (deliveryId == null || deliveryId.isEmpty) return;
    await _repository.recordClick(
      deliveryId,
      eventId: 'in-app-click-${notification.id}',
    );
  }

  // ======================================================
  // SEARCH
  // ======================================================

  void setSearchQuery(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    _scheduleRefresh();
  }

  // ======================================================
  // TYPE FILTER
  // ======================================================

  void setTypeFilter(String type) {
    state = state.copyWith(
      query: state.query.copyWith(selectedType: type.trim()),
    );

    _scheduleRefresh();
  }

  // ======================================================
  // PRIORITY FILTER
  // ======================================================

  void setPriorityFilter(String priority) {
    state = state.copyWith(
      query: state.query.copyWith(selectedPriority: priority.trim()),
    );

    _scheduleRefresh();
  }

  // ======================================================
  // CLEAR FILTERS
  // ======================================================

  void clearAllFilters() {
    state = const NotificationsState(query: NotificationsQuery.empty);

    _scheduleRefresh();
  }

  // ======================================================
  // REFRESH
  // ======================================================

  void refreshNotifications() {
    pagingController.refresh();
  }

  void refresh() {
    refreshNotifications();
  }

  void _scheduleRefresh() {
    _debounce?.cancel();

    _debounce = Timer(AppConstants.searchDebounce, pagingController.refresh);
  }

  // ======================================================
  // ERROR
  // ======================================================

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }
}
