import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/models/filter_models.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/services/auth_service.dart';
import '../../routes/app_pages.dart';
import '../../utils/common.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';

class ChatListController extends GetxController {
  ConversationRepository get _repository =>
      ConversationRepository(BackendApiService.to);
  late final PagingController<int, Conversation> pagingController;

  final RxString searchQuery = ''.obs;
  final RxBool hasActiveFilters = false.obs;
  final RxBool showRecentOnly = false.obs;
  final RxBool showVerifiedOnly = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();

    User.ensureRegistration();
    Conversation.ensureRegistration();
    Message.ensureRegistration();

    pagingController = PagingController<int, Conversation>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );

    ever(searchQuery, (_) => _onFilterChanged());
    ever(showRecentOnly, (_) => _onFilterChanged());
    ever(showVerifiedOnly, (_) => _onFilterChanged());
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

  Future<List<Conversation>> _loadPage(int pageKey) async {
    try {
      final userId = AuthService.to.currentUser.value?.id;
      if (userId == null) return [];

      final result = await _repository.list(
        page: pageKey,
        perPage: 20,
        search: searchQuery.value,
        recentSince: showRecentOnly.value
            ? DateTime.now().subtract(const Duration(days: 7))
            : null,
      );

      return result.items
          .map((r) => Conversation.fromRecord(r))
          .where((c) => _applyLocalSearch(c, userId))
          .toList();
    } catch (e) {
      Common.quickToast(
        title: 'Failed to load conversations',
        description: e.toString(),
      );
      rethrow;
    }
  }

  // =========================
  // FILTER BUILDING
  // =========================

  bool _applyLocalSearch(Conversation conversation, String userId) {
    if (searchQuery.value.isEmpty && !showVerifiedOnly.value) {
      return true;
    }

    final other = conversation.getOtherParticipant(userId);

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      final name = (other?.name ?? '').toLowerCase();
      final email = (other?.email ?? '').toLowerCase();

      if (!name.contains(q) && !email.contains(q)) {
        return false;
      }
    }

    if (showVerifiedOnly.value) {
      if (other?.emailVisibility != true) {
        return false;
      }
    }

    return true;
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
        showRecentOnly.value ||
        showVerifiedOnly.value;
  }

  void clearAllFilters() {
    searchQuery.value = '';
    showRecentOnly.value = false;
    showVerifiedOnly.value = false;
  }

  void refreshConversations() {
    pagingController.refresh();
  }

  // =========================
  // NAVIGATION
  // =========================

  void openChatWith(User otherUser) {
    Get.toNamed(AppRoutes.chatInterface, arguments: otherUser);
  }

  // =========================
  // FILTER UI
  // =========================

  Future<void> showFilterModal(BuildContext context) async {
    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'conversations'.tr,
      fields: [
        FilterField.text('search', 'search'.tr, hint: 'searchConversations'.tr),
        FilterField.boolean('recent', 'Recent Conversations Only'),
        FilterField.boolean('verified', 'Verified Users Only'),
      ],
      initialValues: {
        'search': searchQuery.value,
        'recent': showRecentOnly.value,
        'verified': showVerifiedOnly.value,
      },
    );

    if (result != null && result.isNotEmpty) {
      _applyFilters(result);
    }
  }

  void _applyFilters(FilterResult result) {
    searchQuery.value = result.getValue<String>('search') ?? '';

    showRecentOnly.value = result.getValue<bool>('recent') ?? false;

    showVerifiedOnly.value = result.getValue<bool>('verified') ?? false;
  }

  // =========================
  // UI HELPERS (REQUIRED BY PAGE)
  // =========================

  User? getOtherParticipant(Conversation conversation) {
    final userId = AuthService.to.currentUser.value?.id;
    if (userId == null) return null;

    return conversation.getOtherParticipant(userId);
  }

  String getConversationName(Conversation conversation) {
    final userId = AuthService.to.currentUser.value?.id;
    if (userId == null) return 'Unknown';

    return conversation.getDisplayName(userId);
  }

  String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
