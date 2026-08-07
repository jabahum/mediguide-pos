import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/common.dart';

final notificationsControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => NotificationsController(ref.watch(notificationRepositoryProvider)),
);

class NotificationsController extends ChangeNotifier {
  NotificationsController(this._repository) {
    pagingController = PagingController<int, MyNotification>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );
  }

  final NotificationRepository _repository;
  late final PagingController<int, MyNotification> pagingController;

  String searchQuery = '';
  bool hasActiveFilters = false;
  String selectedType = '';
  String selectedPriority = '';

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    pagingController.dispose();
    super.dispose();
  }

  // =========================
  // DATA LOADING
  // =========================

  Future<List<MyNotification>> _loadPage(int pageKey) async {
    try {
      final result = await _repository.list(
        page: pageKey,
        perPage: AppConstants.pageSize,
        search: searchQuery.isEmpty ? null : searchQuery,
        type: selectedType.isEmpty ? null : selectedType,
        priority: selectedPriority.isEmpty ? null : selectedPriority,
      );
      return result.items;
    } catch (e) {
      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'Error loading notifications $e',
      );

      rethrow;
    }
  }

  Future<void> markRead(MyNotification notification) async {
    if (notification.isRead) return;
    await _repository.markRead(notification.id);
    pagingController.refresh();
  }

  // =========================
  // FILTER HANDLING
  // =========================

  void _onFilterChanged() {
    _updateFilterState();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      pagingController.refresh();
    });
  }

  void _updateFilterState() {
    hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedType.isNotEmpty ||
        selectedPriority.isNotEmpty;
    notifyListeners();
  }

  void clearAllFilters() {
    searchQuery = '';
    selectedType = '';
    selectedPriority = '';
    _onFilterChanged();
  }

  void setTypeFilter(String type) {
    selectedType = type;
    _onFilterChanged();
  }

  void setPriorityFilter(String priority) {
    selectedPriority = priority;
    _onFilterChanged();
  }
}
