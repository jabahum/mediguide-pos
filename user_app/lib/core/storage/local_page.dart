final class LocalPage<T> {
  const LocalPage({
    required this.items,
    required this.totalItems,
    required this.page,
    required this.perPage,
  });

  final List<T> items;
  final int totalItems;
  final int page;
  final int perPage;

  int get totalPages {
    if (totalItems <= 0 || perPage <= 0) {
      return 0;
    }

    return (totalItems / perPage).ceil();
  }

  bool get hasItems => items.isNotEmpty;

  bool get isEmpty => items.isEmpty;

  bool get hasMore => page < totalPages;
}
