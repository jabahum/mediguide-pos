import 'dart:async';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';

class NotificationsController extends GetxController {
  NotificationRepository get _repository =>
      NotificationRepository(BackendApiService.to);
  late final PagingController<int, MyNotification> pagingController;

  final RxString searchQuery = ''.obs;
  final RxBool hasActiveFilters = false.obs;
  final RxString selectedType = ''.obs;
  final RxString selectedPriority = ''.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();

    pagingController = PagingController<int, MyNotification>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );

    ever(searchQuery, (_) => _onFilterChanged());
    ever(selectedType, (_) => _onFilterChanged());
    ever(selectedPriority, (_) => _onFilterChanged());
  }

  @override
  void onClose() {
    _debounce?.cancel();
    pagingController.dispose();
    super.onClose();
  }

  // =========================
  // DATA LOADING
  // =========================

  Future<List<MyNotification>> _loadPage(int pageKey) async {
    try {
      final result = await _repository.list(
        page: pageKey,
        perPage: pageSize,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        type: selectedType.value.isEmpty ? null : selectedType.value,
        priority: selectedPriority.value.isEmpty
            ? null
            : selectedPriority.value,
      );
      return result.items;
    } catch (e) {
      Common.quickToast(
        title: 'Error loading notifications',
        description: e.toString(),
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
    hasActiveFilters.value =
        searchQuery.value.isNotEmpty ||
        selectedType.value.isNotEmpty ||
        selectedPriority.value.isNotEmpty;
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedType.value = '';
    selectedPriority.value = '';
  }

  void setTypeFilter(String type) {
    selectedType.value = type;
  }

  void setPriorityFilter(String priority) {
    selectedPriority.value = priority;
  }
}
