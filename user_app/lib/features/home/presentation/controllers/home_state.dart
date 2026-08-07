// home_state.dart

import 'package:user_app/shared/models/models.dart';

final class HomeState {
  const HomeState({
    this.continueReadingItems = const [],
    this.featuredCalculators = const [],
    this.pinnedGuidelines = const [],
    this.recentlyUpdatedGuidelines = const [],
    this.guidelineCategories = const [],
    this.unreadMessagesCount = 0,
    this.stats = const {},
  });

  final List<ReadingProgress> continueReadingItems;
  final List<Calculator> featuredCalculators;
  final List<Guideline> pinnedGuidelines;
  final List<Guideline> recentlyUpdatedGuidelines;
  final List<GuidelineCategory> guidelineCategories;

  final int unreadMessagesCount;
  final Map<String, int> stats;

  bool get hasContent =>
      continueReadingItems.isNotEmpty ||
      featuredCalculators.isNotEmpty ||
      pinnedGuidelines.isNotEmpty ||
      recentlyUpdatedGuidelines.isNotEmpty ||
      guidelineCategories.isNotEmpty;

  HomeState copyWith({
    List<ReadingProgress>? continueReadingItems,
    List<Calculator>? featuredCalculators,
    List<Guideline>? pinnedGuidelines,
    List<Guideline>? recentlyUpdatedGuidelines,
    List<GuidelineCategory>? guidelineCategories,
    int? unreadMessagesCount,
    Map<String, int>? stats,
  }) {
    return HomeState(
      continueReadingItems: continueReadingItems ?? this.continueReadingItems,
      featuredCalculators: featuredCalculators ?? this.featuredCalculators,
      pinnedGuidelines: pinnedGuidelines ?? this.pinnedGuidelines,
      recentlyUpdatedGuidelines:
          recentlyUpdatedGuidelines ?? this.recentlyUpdatedGuidelines,
      guidelineCategories: guidelineCategories ?? this.guidelineCategories,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      stats: stats ?? this.stats,
    );
  }
}
