import 'package:user_app/shared/models/models.dart';

enum GuidelineRouteFilterType { all, category, categoryTree, indexItem, tag }

final class GuidelinesRouteState {
  const GuidelinesRouteState({
    this.pageTitle = 'All Guidelines',
    this.filterType = GuidelineRouteFilterType.all,
    this.selectedIndex,
    this.routeCategoryId = '',
    this.routeCategoryIds = const [],
    this.selectedTagId = '',
  });

  final String pageTitle;
  final GuidelineRouteFilterType filterType;
  final GuidelineIndex? selectedIndex;

  final String routeCategoryId;
  final List<String> routeCategoryIds;

  final String selectedTagId;

  bool get isInIndexMode => filterType == GuidelineRouteFilterType.indexItem;

  bool get isInCategoryMode =>
      filterType == GuidelineRouteFilterType.category ||
      filterType == GuidelineRouteFilterType.categoryTree;

  bool get isInTagMode => filterType == GuidelineRouteFilterType.tag;

  bool get hasPermanentFilter =>
      isInIndexMode || isInCategoryMode || isInTagMode;

  bool get isEmergencyRoute =>
      isInCategoryMode && pageTitle == 'Emergency Guidelines';

  String get effectivePageTitle {
    if (isInIndexMode) {
      return selectedIndex?.title ?? pageTitle;
    }

    return pageTitle;
  }

  GuidelinesRouteState copyWith({
    String? pageTitle,
    GuidelineRouteFilterType? filterType,
    GuidelineIndex? selectedIndex,
    bool clearSelectedIndex = false,
    String? routeCategoryId,
    List<String>? routeCategoryIds,
    String? selectedTagId,
  }) {
    return GuidelinesRouteState(
      pageTitle: pageTitle ?? this.pageTitle,
      filterType: filterType ?? this.filterType,
      selectedIndex: clearSelectedIndex
          ? null
          : selectedIndex ?? this.selectedIndex,
      routeCategoryId: routeCategoryId ?? this.routeCategoryId,
      routeCategoryIds: routeCategoryIds ?? this.routeCategoryIds,
      selectedTagId: selectedTagId ?? this.selectedTagId,
    );
  }
}
