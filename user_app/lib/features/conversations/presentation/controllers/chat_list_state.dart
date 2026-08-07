// chat_list_state.dart

import 'package:user_app/features/conversations/presentation/controllers/chat_list_query.dart';

final class ChatListState {
  const ChatListState({this.query = ChatListQuery.empty});

  final ChatListQuery query;

  String get searchQuery => query.search;

  bool get showRecentOnly => query.showRecentOnly;

  bool get showVerifiedOnly => query.showVerifiedOnly;

  bool get hasActiveFilters => query.hasActiveFilters;

  ChatListState copyWith({ChatListQuery? query}) {
    return ChatListState(query: query ?? this.query);
  }
}
