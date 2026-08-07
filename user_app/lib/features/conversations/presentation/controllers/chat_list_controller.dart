// chat_list_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_list_query.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_list_state.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'chat_list_controller.g.dart';

@riverpod
class ChatListController extends _$ChatListController {
  Timer? _debounce;

  late final PagingController<int, Conversation> pagingController;

  ConversationRepository get _repository =>
      ref.read(conversationRepositoryProvider);

  String? get currentUserId =>
      ref.read(authControllerProvider).valueOrNull?.user?.id;

  @override
  ChatListState build() {
    pagingController = PagingController<int, Conversation>(
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

    return const ChatListState();
  }

  // ======================================================
  // DATA LOADING
  // ======================================================

  Future<List<Conversation>> _loadPage(int pageKey) async {
    try {
      final userId = currentUserId;

      if (userId == null) {
        return const [];
      }

      final query = state.query;

      final result = await _repository.list(
        page: pageKey,
        perPage: AppConstants.pageSize,
        search: query.search.trim().isEmpty ? null : query.search.trim(),
        recentSince: query.showRecentOnly
            ? DateTime.now().subtract(const Duration(days: 7))
            : null,
      );

      return result.items
          .where((conversation) => _applyLocalFilters(conversation, userId))
          .toList(growable: false);
    } catch (error) {
      _showError('errorLoadingConversations'.tr);

      rethrow;
    }
  }

  bool _applyLocalFilters(Conversation conversation, String userId) {
    final query = state.query;

    if (query.search.isEmpty && !query.showVerifiedOnly) {
      return true;
    }

    final other = conversation.getOtherParticipant(userId);

    if (query.search.isNotEmpty) {
      final value = query.search.toLowerCase();

      final name = (other?.name ?? '').toLowerCase();

      final email = (other?.email ?? '').toLowerCase();

      if (!name.contains(value) && !email.contains(value)) {
        return false;
      }
    }

    if (query.showVerifiedOnly && other?.verified != true) {
      return false;
    }

    return true;
  }

  // ======================================================
  // FILTERS
  // ======================================================

  void setSearchQuery(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    _scheduleRefresh();
  }

  void setRecentOnly(bool value) {
    state = state.copyWith(query: state.query.copyWith(showRecentOnly: value));

    _scheduleRefresh();
  }

  void setVerifiedOnly(bool value) {
    state = state.copyWith(
      query: state.query.copyWith(showVerifiedOnly: value),
    );

    _scheduleRefresh();
  }

  void clearAllFilters() {
    state = const ChatListState(query: ChatListQuery.empty);

    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _debounce?.cancel();

    _debounce = Timer(AppConstants.searchDebounce, pagingController.refresh);
  }

  // ======================================================
  // REFRESH
  // ======================================================

  void refreshConversations() {
    pagingController.refresh();
  }

  // ======================================================
  // FILTER MODAL
  // ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final query = state.query;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'conversations'.tr,
      fields: [
        FilterField.text('search', 'search'.tr, hint: 'searchConversations'.tr),
        FilterField.boolean('recent', 'Recent Conversations Only'),
        FilterField.boolean('verified', 'Verified Users Only'),
      ],
      initialValues: {
        if (query.search.isNotEmpty) 'search': query.search,
        'recent': query.showRecentOnly,
        'verified': query.showVerifiedOnly,
      },
    );

    if (result == null) {
      return;
    }

    state = state.copyWith(
      query: ChatListQuery(
        search: result.getValue<String>('search')?.trim() ?? '',
        showRecentOnly: result.getValue<bool>('recent') ?? false,
        showVerifiedOnly: result.getValue<bool>('verified') ?? false,
      ),
    );

    _scheduleRefresh();
  }

  // ======================================================
  // CONVERSATION HELPERS
  // ======================================================

  User? getOtherParticipant(Conversation conversation) {
    final userId = currentUserId;

    if (userId == null) {
      return null;
    }

    return conversation.getOtherParticipant(userId);
  }

  String getConversationName(Conversation conversation) {
    final userId = currentUserId;

    if (userId == null) {
      return 'Unknown';
    }

    return conversation.getDisplayName(userId);
  }

  String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${dateTime.day}/'
        '${dateTime.month}/'
        '${dateTime.year}';
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
