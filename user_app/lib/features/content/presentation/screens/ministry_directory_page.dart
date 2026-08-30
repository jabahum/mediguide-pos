import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/content/data/models/ministry_directory.dart';
import 'package:user_app/features/content/presentation/controllers/ministry_directory_controller.dart';

import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/ministry_directory_card.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

part '../widgets/ministry_directory_page_directory_browse_card.dart';
part '../widgets/ministry_directory_page_active_directory_filters_banner.dart';
part '../widgets/ministry_directory_page_directory_card_shell.dart';

class MinistryDirectoryPage extends ConsumerStatefulWidget {
  const MinistryDirectoryPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<MinistryDirectoryPage> createState() =>
      _MinistryDirectoryPageState();
}

class _MinistryDirectoryPageState extends ConsumerState<MinistryDirectoryPage> {
  @override
  void initState() {
    super.initState();

    final arguments = widget.arguments;

    if (arguments is Map && arguments['treeFilters'] is Map) {
      final filters = Map<String, dynamic>.from(
        arguments['treeFilters'] as Map,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ref
            .read(ministryDirectoryControllerProvider.notifier)
            .applyTreeFilters(filters);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ministryDirectoryControllerProvider);

    final controller = ref.read(ministryDirectoryControllerProvider.notifier);

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ministryDirectory'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Official contacts and departments',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          FilterButton(
            hasActiveFilters: state.hasActiveFilters,
            onPressed: () {
              controller.showAdvancedFilter(context);
            },
            onReset: state.hasActiveFilters ? controller.resetFilters : null,
            tooltip: 'filterDirectory'.tr,
          ),
          AppSpacing.hGapXs,
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // DIRECTORY CONTEXT
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DirectoryBrowseCard(
                      hasActiveFilters: state.hasActiveFilters,
                      onOpenFilters: () {
                        controller.showAdvancedFilter(context);
                      },
                    ),

                    if (state.hasActiveFilters) ...[
                      AppSpacing.gapMd,

                      _ActiveDirectoryFiltersBanner(
                        onEdit: () {
                          controller.showAdvancedFilter(context);
                        },
                        onClear: controller.resetFilters,
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      state.hasActiveFilters
                          ? 'Matching directory entries'
                          : 'Directory',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      state.hasActiveFilters
                          ? 'Showing ministry contacts matching your current filters.'
                          : 'Browse official departments, contacts and support offices.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    AppSpacing.gapSm,
                  ],
                ),
              ),
            ),

            // =================================================================
            // DIRECTORY LIST
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, MinistryDirectory>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, MinistryDirectory>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<MinistryDirectory>(
                      // =====================================================
                      // ITEM
                      // =====================================================
                      itemBuilder: (context, entry, index) {
                        return _DirectoryCardShell(
                          child: MinistryDirectoryCard(
                            entry: entry,
                            index: index,
                          ),
                        );
                      },

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading ministry directory...',
                        );
                      },

                      // =====================================================
                      // NEXT PAGE LOADING
                      // =====================================================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // =====================================================
                      // FIRST PAGE ERROR
                      // =====================================================
                      firstPageErrorIndicatorBuilder: (_) {
                        return AppErrorView(
                          error:
                              pagingState.error ??
                              'Unable to load ministry directory',
                          title: 'Failed to load directory',
                          message:
                              'Please check your connection and try again.',
                          onRetry: fetchNextPage,
                        );
                      },

                      // =====================================================
                      // NEXT PAGE ERROR
                      // =====================================================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'Failed to load more entries',
                          icon: LucideIcons.landmark,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No entries match your filters',
                            description:
                                'Try adjusting your search or filters.',
                            actionLabel: 'clearFilters'.tr,
                            onAction: controller.resetFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: 'No directory entries found',
                          description:
                              'Directory entries will appear here when available.',
                        );
                      },

                      // =====================================================
                      // END
                      // =====================================================
                      noMoreItemsIndicatorBuilder: (_) {
                        return Padding(
                          padding: AppSpacing.vPaddingMd,
                          child: PaginationIndicators.noMoreItems(),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// BROWSE CARD
// ===========================================================================
