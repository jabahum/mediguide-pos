import 'dart:async';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';

class NotificationsController extends GetxController {
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
      final filter = _buildFilter();

      final result = await BackendApiService.to.getRecordList(
        collectionName: 'notifications',
        page: pageKey,
        perPage: pageSize,
        filter: filter.isEmpty ? null : filter,
        sort: '-created',
      );

      return result.items.map((r) => MyNotification.fromRecord(r)).toList();
    } catch (e) {
      Common.quickToast(
        title: 'Error loading notifications',
        description: e.toString(),
      );
      rethrow;
    }
  }

  // =========================
  // FILTER BUILDER
  // =========================

  String _buildFilter() {
    final filters = <String>[];

    final userId = AuthService.to.currentUser.value?.id;

    if (userId != null) {
      filters.add('(user_id = "" || user_id = "$userId")');
    } else {
      filters.add('user_id = ""');
    }

    if (searchQuery.value.isNotEmpty) {
      final q = BackendApiService.escapeFilterValue(searchQuery.value);
      filters.add('(title ~ "$q" || message ~ "$q")');
    }

    if (selectedType.value.isNotEmpty) {
      final type = BackendApiService.escapeFilterValue(selectedType.value);
      filters.add('type = "$type"');
    }

    if (selectedPriority.value.isNotEmpty) {
      final priority = BackendApiService.escapeFilterValue(
        selectedPriority.value,
      );
      filters.add('priority = "$priority"');
    }

    return filters.join(' && ');
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
