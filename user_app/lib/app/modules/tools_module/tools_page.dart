import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/models.dart';
import '../../routes/app_pages.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_button.dart';
import '../../widgets/pagination_indicators.dart';
import '../../../app/modules/tools_module/tools_controller.dart';
import 'widgets/calculator_card.dart';

class ToolsPage extends ConsumerStatefulWidget {
  const ToolsPage({super.key});

  @override
  ConsumerState<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends ConsumerState<ToolsPage> {
  late final Object? _routeArguments;

  static const List<_ToolTypeFilter> _toolFilters = [
    _ToolTypeFilter(label: 'All', icon: LucideIcons.layoutGrid, tabIndex: 0),
    _ToolTypeFilter(
      label: 'Calculators',
      icon: LucideIcons.calculator,
      tabIndex: 1,
    ),
    _ToolTypeFilter(
      label: 'Decision Tools',
      icon: LucideIcons.gitBranch,
      tabIndex: 2,
    ),
    _ToolTypeFilter(
      label: 'Checklists',
      icon: LucideIcons.listChecks,
      tabIndex: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _routeArguments = Get.arguments;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(toolsControllerProvider(_routeArguments));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Text(
          'Tools'.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          FilterButton(
            hasActiveFilters: controller.hasActiveFilters,
            onPressed: () => controller.showFilterModal(context),
            onReset: controller.clearAllFilters,
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(controller.refreshData),
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
                child: _ToolsHeaderCard(
                  onOpenFilters: () => controller.showFilterModal(context),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _ToolTypeFilterBar(
                  filters: _toolFilters,
                  selectedIndex: controller.selectedTabIndex,
                  onChanged: controller.onTabChanged,
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
              sliver: PagingListener<int, Calculator>(
                controller: controller.pagingController,
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, Calculator>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Calculator>(
                      itemBuilder: (context, calculator, index) {
                        return _ToolCardShell(
                          child: CalculatorTile(
                            calculator: calculator,
                            onTap: () => Get.toNamed(
                              AppRoutes.useCalculator,
                              arguments: calculator,
                            ),
                            showDivider: false,
                          ),
                        );
                      },
                      firstPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageError(
                            onRetry: fetchNextPage,
                            title: 'Failed to load tools',
                            subtitle:
                                'Please check your connection and try again',
                            icon: LucideIcons.calculator,
                          ),
                      newPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageError(
                            onRetry: fetchNextPage,
                            title: 'Failed to load more tools',
                            icon: LucideIcons.calculator,
                          ),
                      firstPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageProgress(),
                      newPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageProgress(),
                      noItemsFoundIndicatorBuilder: (context) {
                        final hasFilters = controller.hasActiveFilters;

                        return _EmptyToolsState(
                          hasFilters: hasFilters,
                          onClearFilters: controller.clearAllFilters,
                        );
                      },
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
    );
  }
}

class _ToolsHeaderCard extends StatelessWidget {
  final VoidCallback onOpenFilters;

  const _ToolsHeaderCard({required this.onOpenFilters});

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
            child: Icon(LucideIcons.calculator, color: cs.primary, size: 28),
          ),
          AppSpacing.md.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Tools',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use calculators, decision tools and checklists to support clinical care.',
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
            tooltip: 'Filter tools',
          ),
        ],
      ),
    );
  }
}

class _ToolTypeFilterBar extends StatelessWidget {
  final List<_ToolTypeFilter> filters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ToolTypeFilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => AppSpacing.sm.gap,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedIndex == filter.tabIndex;

          return _ToolTypeChip(
            label: filter.label,
            icon: filter.icon,
            selected: selected,
            onTap: () {
              if (selected) return;
              onChanged(filter.tabIndex);
            },
          );
        },
      ),
    );
  }
}

class _ToolTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToolTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16, color: selected ? cs.onPrimary : cs.primary),
      label: Text(label),
      labelStyle: context.textTheme.labelMedium?.copyWith(
        color: selected ? cs.onPrimary : cs.onSurface,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerLowest,
      side: BorderSide(
        color: selected
            ? cs.primary
            : cs.outlineVariant.withValues(alpha: 0.45),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _ToolCardShell extends StatelessWidget {
  final Widget child;

  const _ToolCardShell({required this.child});

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

class _EmptyToolsState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyToolsState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(LucideIcons.calculator, color: cs.primary, size: 34),
          ),
          AppSpacing.md.gap,
          Text(
            hasFilters ? 'No tools match filters' : 'No tools found',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try adjusting your search or filters.'
                : 'Tools will appear here when available.',
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
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolTypeFilter {
  final String label;
  final IconData icon;
  final int tabIndex;

  const _ToolTypeFilter({
    required this.label,
    required this.icon,
    required this.tabIndex,
  });
}
