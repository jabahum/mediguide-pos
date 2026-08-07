import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

final chatListControllerProvider = ChangeNotifierProvider.autoDispose((ref) {
  final userId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
  return ChatListController(
    ref.watch(conversationRepositoryProvider),
    currentUserId: userId,
  );
});

class ChatListController extends ChangeNotifier {
  ChatListController(this._repository, {required this.currentUserId}) {
    pagingController = PagingController<int, Conversation>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );
  }

  final ConversationRepository _repository;
  final String? currentUserId;
  late final PagingController<int, Conversation> pagingController;

  String searchQuery = '';
  bool hasActiveFilters = false;
  bool showRecentOnly = false;
  bool showVerifiedOnly = false;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    pagingController.dispose();
    super.dispose();
  }

  Future<List<Conversation>> _loadPage(int pageKey) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final result = await _repository.list(
        page: pageKey,
        perPage: 20,
        search: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
        recentSince: showRecentOnly
            ? DateTime.now().subtract(const Duration(days: 7))
            : null,
      );

      return result.items
          .where((conversation) => _applyLocalFilters(conversation, userId))
          .toList();
    } catch (error) {
      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'errorLoadingConversations'.tr,
      );

      rethrow;
    }
  }

  bool _applyLocalFilters(Conversation conversation, String userId) {
    if (searchQuery.isEmpty && !showVerifiedOnly) return true;
    final other = conversation.getOtherParticipant(userId);

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final name = (other?.name ?? '').toLowerCase();
      final email = (other?.email ?? '').toLowerCase();
      if (!name.contains(query) && !email.contains(query)) return false;
    }

    return !showVerifiedOnly || other?.verified == true;
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    _onFilterChanged();
  }

  void setRecentOnly(bool value) {
    showRecentOnly = value;
    _onFilterChanged();
  }

  void setVerifiedOnly(bool value) {
    showVerifiedOnly = value;
    _onFilterChanged();
  }

  void _onFilterChanged() {
    hasActiveFilters =
        searchQuery.isNotEmpty || showRecentOnly || showVerifiedOnly;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      pagingController.refresh,
    );
  }

  void clearAllFilters() {
    searchQuery = '';
    showRecentOnly = false;
    showVerifiedOnly = false;
    _onFilterChanged();
  }

  void refreshConversations() => pagingController.refresh();

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
        'search': searchQuery,
        'recent': showRecentOnly,
        'verified': showVerifiedOnly,
      },
    );

    if (result == null || result.isEmpty) return;
    searchQuery = result.getValue<String>('search') ?? '';
    showRecentOnly = result.getValue<bool>('recent') ?? false;
    showVerifiedOnly = result.getValue<bool>('verified') ?? false;
    _onFilterChanged();
  }

  User? getOtherParticipant(Conversation conversation) {
    final userId = currentUserId;
    return userId == null ? null : conversation.getOtherParticipant(userId);
  }

  String getConversationName(Conversation conversation) {
    final userId = currentUserId;
    return userId == null ? 'Unknown' : conversation.getDisplayName(userId);
  }

  String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
