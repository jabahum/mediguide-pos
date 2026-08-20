import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/consultants/data/models/consultant.dart';
import 'package:user_app/features/consultants/presentation/controllers/consultants_controller.dart';
import 'package:user_app/features/consultants/presentation/widgets/consultant_card.dart';

import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

class ConsultantsPage extends ConsumerStatefulWidget {
  const ConsultantsPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<ConsultantsPage> createState() => _ConsultantsPageState();
}

class _ConsultantsPageState extends ConsumerState<ConsultantsPage> {
  late final Object? _routeArguments;

  @override
  void initState() {
    super.initState();
    _routeArguments = widget.arguments;
  }

  @override
  Widget build(BuildContext context) {
    final provider = consultantsControllerProvider(_routeArguments);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

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
              'consultants'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Clinical specialists and expert contacts',
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
              controller.showFilterModal(context);
            },
            onReset: state.hasActiveFilters ? controller.clearAllFilters : null,
          ),
          AppSpacing.hGapXs,
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // CONTEXT + FILTERS
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
                    _ConsultantBrowseCard(
                      hasActiveFilters: state.hasActiveFilters,
                      onOpenFilters: () {
                        controller.showFilterModal(context);
                      },
                    ),

                    if (state.hasActiveFilters) ...[
                      AppSpacing.gapMd,
                      _ActiveConsultantFiltersBanner(
                        onEdit: () {
                          controller.showFilterModal(context);
                        },
                        onClear: controller.clearAllFilters,
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      state.hasActiveFilters
                          ? 'Matching consultants'
                          : 'Consultants',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      state.hasActiveFilters
                          ? 'Showing consultants matching your current filters.'
                          : 'Browse specialists by expertise, organization and location.',
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
            // CONSULTANT LIST
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, Consultant>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, Consultant>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Consultant>(
                      // =====================================================
                      // ITEM
                      // =====================================================
                      itemBuilder: (context, consultant, index) {
                        return _ConsultantCardShell(
                          child: ConsultantCard(
                            consultant: consultant,
                            onTap: () {
                              controller.showConsultantDetail(
                                context,
                                consultant,
                              );
                            },
                          ),
                        );
                      },

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading consultants...',
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
                              pagingState.error ?? 'Unable to load consultants',
                          title: 'failedToLoadConsultants'.tr,
                          message: 'pleaseCheckConnectionAndTryAgain'.tr,
                          onRetry: fetchNextPage,
                        );
                      },

                      // =====================================================
                      // NEXT PAGE ERROR
                      // =====================================================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'failedToLoadMoreConsultants'.tr,
                          icon: LucideIcons.stethoscope,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'noConsultantsMatchFilters'.tr,
                            description: 'tryAdjustingSearchOrFilters'.tr,
                            actionLabel: 'clearFilters'.tr,
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: 'noConsultantsFound'.tr,
                          description: 'consultantsWillAppearHere'.tr,
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

class _ConsultantBrowseCard extends StatelessWidget {
  const _ConsultantBrowseCard({
    required this.hasActiveFilters,
    required this.onOpenFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenFilters,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.stethoscope,
                  color: colors.primary,
                  size: 21,
                ),
              ),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find a consultant',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasActiveFilters
                          ? 'Filters are applied. Tap to adjust them.'
                          : 'Filter by speciality, organization, region or other available attributes.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.hGapSm,

              Icon(
                LucideIcons.slidersHorizontal,
                color: colors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ACTIVE FILTERS
// ===========================================================================

class _ActiveConsultantFiltersBanner extends StatelessWidget {
  const _ActiveConsultantFiltersBanner({
    required this.onEdit,
    required this.onClear,
  });

  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.listFilter,
            size: 18,
            color: colors.onSecondaryContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              'Consultant filters applied',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          TextButton(onPressed: onEdit, child: const Text('Edit')),

          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

// ===========================================================================
// CARD SHELL
// ===========================================================================

class _ConsultantCardShell extends StatelessWidget {
  const _ConsultantCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
