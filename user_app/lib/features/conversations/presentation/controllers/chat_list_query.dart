// chat_list_query.dart

final class ChatListQuery {
  const ChatListQuery({
    this.search = '',
    this.showRecentOnly = false,
    this.showVerifiedOnly = false,
  });

  static const empty = ChatListQuery();

  final String search;
  final bool showRecentOnly;
  final bool showVerifiedOnly;

  bool get hasActiveFilters =>
      search.isNotEmpty || showRecentOnly || showVerifiedOnly;

  ChatListQuery copyWith({
    String? search,
    bool? showRecentOnly,
    bool? showVerifiedOnly,
  }) {
    return ChatListQuery(
      search: search ?? this.search,
      showRecentOnly: showRecentOnly ?? this.showRecentOnly,
      showVerifiedOnly: showVerifiedOnly ?? this.showVerifiedOnly,
    );
  }
}
