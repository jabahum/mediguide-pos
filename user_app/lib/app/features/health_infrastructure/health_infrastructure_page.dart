import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/health_facility.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_button.dart';
import '../../widgets/pagination_indicators.dart';
import 'health_infrastructure_controller.dart';
import 'widgets/health_facility_card.dart';

class HealthInfrastructurePage extends ConsumerStatefulWidget {
  const HealthInfrastructurePage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<HealthInfrastructurePage> createState() =>
      _HealthInfrastructurePageState();
}

class _HealthInfrastructurePageState
    extends ConsumerState<HealthInfrastructurePage> {
  late final Object? _routeArguments;

  @override
  void initState() {
    super.initState();
    _routeArguments = widget.arguments;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      healthInfrastructureControllerProvider(_routeArguments),
    );
    final cs = context.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.healthInfrastructure.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          FilterButton(
            hasActiveFilters: controller.hasActiveFilters,
            onPressed: () => controller.showFilterModal(context),
            onReset: controller.hasActiveFilters
                ? controller.clearAllFilters
                : null,
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.pagingController.refresh();
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
                child: _HealthInfrastructureHeaderCard(
                  onOpenFilters: () => controller.showFilterModal(context),
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
              sliver: PagingListener<int, HealthFacility>(
                controller: controller.pagingController,
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, HealthFacility>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<HealthFacility>(
                      itemBuilder: (context, facility, index) {
                        return _HealthFacilityCardShell(
                          child: HealthFacilityCard(
                            facility: facility,
                            onTap: () =>
                                controller.goToFacilityDetail(facility),
                            showDivider: false,
                          ),
                        );
                      },

                      // ================= ERROR STATES =================
                      firstPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageError(
                            onRetry: fetchNextPage,
                            title: AppTranslationKey.failedToLoadFacilities.tr,
                            subtitle: AppTranslationKey
                                .pleaseCheckConnectionAndTryAgain
                                .tr,
                            icon: LucideIcons.building2,
                          ),

                      newPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageError(
                            onRetry: fetchNextPage,
                            title:
                                AppTranslationKey.failedToLoadMoreFacilities.tr,
                            icon: LucideIcons.building2,
                          ),

                      // ================= LOADING STATES =================
                      firstPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageProgress(),

                      newPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageProgress(),

                      // ================= EMPTY STATE =================
                      noItemsFoundIndicatorBuilder: (context) {
                        return _EmptyFacilitiesState(
                          hasFilters: controller.hasActiveFilters,
                          onClearFilters: controller.clearAllFilters,
                        );
                      },

                      // ================= END STATE =================
                      noMoreItemsIndicatorBuilder: (context) =>
                          PaginationIndicators.noMoreItems(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: cs.surface,
    );
  }
}

class _HealthInfrastructureHeaderCard extends StatelessWidget {
  final VoidCallback onOpenFilters;

  const _HealthInfrastructureHeaderCard({required this.onOpenFilters});

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
            child: Icon(LucideIcons.building2, color: cs.primary, size: 28),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.healthInfrastructure.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find health facilities, services and care locations near you.',
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
            tooltip: 'Filter facilities',
          ),
        ],
      ),
    );
  }
}

class _HealthFacilityCardShell extends StatelessWidget {
  final Widget child;

  const _HealthFacilityCardShell({required this.child});

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

class _EmptyFacilitiesState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyFacilitiesState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final title = hasFilters
        ? AppTranslationKey.noFacilitiesMatchFilters.tr
        : AppTranslationKey.noFacilitiesFound.tr;

    final subtitle = hasFilters
        ? AppTranslationKey.tryAdjustingSearchOrFilters.tr
        : AppTranslationKey.facilitiesWillAppearHere.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              hasFilters ? LucideIcons.searchX : LucideIcons.building2,
              color: cs.primary,
              size: 36,
            ),
          ),

          AppSpacing.md.gap,

          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          if (hasFilters) ...[
            AppSpacing.lg.gap,
            FilledButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(LucideIcons.x),
              label: Text(AppTranslationKey.clearFilters.tr),
            ),
          ],
        ],
      ),
    );
  }
}
