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

    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          'ministryDirectory'.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
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
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _DirectoryHeaderCard(
                  onOpenFilters: () {
                    controller.showAdvancedFilter(context);
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, MinistryDirectory>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, MinistryDirectory>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<MinistryDirectory>(
                      itemBuilder: (context, entry, index) {
                        return _DirectoryCardShell(
                          child: MinistryDirectoryCard(
                            entry: entry,
                            index: index,
                          ),
                        );
                      },

                      // =========================
                      // FIRST PAGE LOADING
                      // =========================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading ministry directory...',
                        );
                      },

                      // =========================
                      // NEXT PAGE LOADING
                      // =========================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // =========================
                      // FIRST PAGE ERROR
                      // =========================
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

                      // =========================
                      // NEXT PAGE ERROR
                      // =========================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'Failed to load more entries',
                          icon: LucideIcons.phone,
                        );
                      },

                      // =========================
                      // EMPTY
                      // =========================
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

                      // =========================
                      // END
                      // =========================
                      noMoreItemsIndicatorBuilder: (_) {
                        return PaginationIndicators.noMoreItems();
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

class _DirectoryHeaderCard extends StatelessWidget {
  const _DirectoryHeaderCard({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(LucideIcons.phone, color: cs.primary, size: 28),
          ),
          AppSpacing.md.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ministryDirectory'.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find ministry contacts, emergency numbers and support offices.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.sm.gap,
          IconButton.filledTonal(
            onPressed: onOpenFilters,
            icon: const Icon(LucideIcons.slidersHorizontal),
            tooltip: 'filterDirectory'.tr,
          ),
        ],
      ),
    );
  }
}

class _DirectoryCardShell extends StatelessWidget {
  const _DirectoryCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
