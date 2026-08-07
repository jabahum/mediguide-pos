// guidelines_indexer_state.dart

import 'package:animated_tree_view/tree_view/tree_node.dart';

import 'package:user_app/features/guidelines/data/models/guideline_index.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_tree_filter.dart';

final class GuidelinesIndexerState {
  const GuidelinesIndexerState({
    required this.rootTree,
    required this.visibleTree,
    this.filters = GuidelinesTreeFilter.empty,
    this.allRecords = const [],
    this.channel,
    this.isLoading = true,
    this.hasLoadError = false,
    this.errorMessage,
  });

  final TreeNode<GuidelineIndex> rootTree;
  final TreeNode<GuidelineIndex> visibleTree;

  final GuidelinesTreeFilter filters;
  final List<GuidelineIndex> allRecords;

  final String? channel;

  final bool isLoading;
  final bool hasLoadError;
  final String? errorMessage;

  bool get hasActiveFilters => filters.hasFilters;

  int get totalSections => allRecords.length;

  String get channelTitle {
    final value = channel?.toLowerCase() ?? '';

    if (value.contains('red')) {
      return 'Red Channel';
    }

    if (value.contains('blue')) {
      return 'Blue Channel';
    }

    return 'Browse Guidelines';
  }

  String get pageSubtitle {
    if (hasActiveFilters) {
      return 'Showing matching guideline sections';
    }

    return 'Choose a section to view related guidelines';
  }

  GuidelinesIndexerState copyWith({
    TreeNode<GuidelineIndex>? rootTree,
    TreeNode<GuidelineIndex>? visibleTree,
    GuidelinesTreeFilter? filters,
    List<GuidelineIndex>? allRecords,
    String? channel,
    bool clearChannel = false,
    bool? isLoading,
    bool? hasLoadError,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return GuidelinesIndexerState(
      rootTree: rootTree ?? this.rootTree,
      visibleTree: visibleTree ?? this.visibleTree,
      filters: filters ?? this.filters,
      allRecords: allRecords ?? this.allRecords,
      channel: clearChannel ? null : channel ?? this.channel,
      isLoading: isLoading ?? this.isLoading,
      hasLoadError: hasLoadError ?? this.hasLoadError,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
