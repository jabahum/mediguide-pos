import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:user_app/app/core/navigation/app_navigator.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/guideline.dart';
import '../../core/navigation/app_router.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_button.dart';
import '../../widgets/pagination_indicators.dart';
import 'guidelines_controller.dart';
import 'widgets/guideline_card.dart';

class GuidelinesPage extends ConsumerStatefulWidget {
  const GuidelinesPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<GuidelinesPage> createState() => _GuidelinesPageState();
}

class _GuidelinesPageState extends ConsumerState<GuidelinesPage> {
  late final Object? _routeArguments;

  @override
  void initState() {
    super.initState();
    _routeArguments = widget.arguments;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(guidelinesControllerProvider(_routeArguments));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.effectivePageTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          FilterButton(
            hasActiveFilters: controller.hasActiveFilters,
            onPressed: () => controller.showFilterModal(context),
            onReset: controller.clearAllFilters,
          ),
          if (controller.hasPermanentFilter)
            IconButton(
              tooltip: 'Show all guidelines',
              onPressed: controller.showAllGuidelines,
              icon: const Icon(LucideIcons.listRestart),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.pagingController.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.hPaddingSm + AppSpacing.vPaddingSm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GuidelinesHeader(controller: controller),
                    AppSpacing.md.gap,
                    _GuidelinesSearchBox(controller: controller),
                    AppSpacing.md.gap,
                    _QuickFilters(controller: controller),
                    if (controller.hasPermanentFilter ||
                        controller.hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _ActiveGuidelineContext(
                          title: controller.effectivePageTitle,
                          hasPermanentFilter: controller.hasPermanentFilter,
                          hasFilters: controller.hasActiveFilters,
                          onClearFilters: controller.clearAllFilters,
                          onShowAll: controller.showAllGuidelines,
                        ),
                      ),
                    AppSpacing.md.gap,
                  ],
                ),
              ),
            ),

            PagingListener<int, Guideline>(
              controller: controller.pagingController,
              builder: (context, state, fetchNextPage) {
                return PagedSliverList<int, Guideline>.separated(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  separatorBuilder: (_, _) => AppSpacing.sm.gap,
                  builderDelegate: PagedChildBuilderDelegate<Guideline>(
                    itemBuilder: (context, item, index) {
                      return Padding(
                        padding: AppSpacing.hPaddingSm,
                        child: GuidelineCard(
                          guideline: item,
                          onTap: () => _openGuideline(item),
                        ),
                      );
                    },
                    firstPageErrorIndicatorBuilder: (_) {
                      return PaginationIndicators.firstPageError(
                        onRetry: fetchNextPage,
                        title: 'Failed to load guidelines',
                        subtitle: 'Check your connection and try again',
                        icon: LucideIcons.stethoscope,
                      );
                    },
                    newPageErrorIndicatorBuilder: (_) {
                      return PaginationIndicators.newPageError(
                        onRetry: fetchNextPage,
                        title: 'Failed to load more',
                        icon: LucideIcons.stethoscope,
                      );
                    },
                    firstPageProgressIndicatorBuilder: (_) {
                      return PaginationIndicators.firstPageProgress();
                    },
                    newPageProgressIndicatorBuilder: (_) {
                      return PaginationIndicators.newPageProgress();
                    },
                    noItemsFoundIndicatorBuilder: (_) {
                      return _GuidelinesEmptyState(
                        icon: _getEmptyIcon(controller),
                        title: _getEmptyTitle(controller),
                        subtitle: _getEmptySubtitle(controller),
                        hasFilters: controller.hasActiveFilters,
                        hasPermanentFilter: controller.hasPermanentFilter,
                        onClearFilters: controller.clearAllFilters,
                        onShowAll: controller.showAllGuidelines,
                      );
                    },
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

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  void _openGuideline(Guideline guideline) {
    AppNavigator.pushNamed(AppRoutes.readGuideline, arguments: guideline);
  }

  IconData _getEmptyIcon(GuidelinesController controller) {
    if (controller.isInCategoryMode) {
      return LucideIcons.folderOpen;
    }

    if (controller.isInTagMode) {
      return LucideIcons.tags;
    }

    if (controller.isInIndexMode) {
      return LucideIcons.bookOpenText;
    }

    return LucideIcons.stethoscope;
  }

  String _getEmptyTitle(GuidelinesController controller) {
    final hasFilters = controller.hasActiveFilters;

    if (hasFilters) {
      return 'No matching guidelines';
    }

    if (controller.isInCategoryMode) {
      return 'No guidelines in this category';
    }

    if (controller.isInTagMode) {
      return 'No guidelines with this tag';
    }

    return 'No guidelines found';
  }

  String _getEmptySubtitle(GuidelinesController controller) {
    final hasFilters = controller.hasActiveFilters;

    if (hasFilters) {
      return 'Try adjusting your search or filters.';
    }

    if (controller.isInCategoryMode) {
      return 'This category does not have published guidelines yet.';
    }

    if (controller.isInTagMode) {
      return 'No published guidelines are currently linked to this tag.';
    }

    return 'Published clinical guidelines will appear here once available.';
  }
}

class _GuidelinesHeader extends StatelessWidget {
  final GuidelinesController controller;

  const _GuidelinesHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final title = controller.effectivePageTitle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
            child: Icon(
              controller.hasPermanentFilter
                  ? LucideIcons.folderOpen
                  : LucideIcons.library,
              color: cs.primary,
            ),
          ),
          AppSpacing.md.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.hasPermanentFilter
                      ? 'Browse guidelines in this section or search within results.'
                      : 'Search and browse all published clinical guidelines.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidelinesSearchBox extends StatefulWidget {
  final GuidelinesController controller;

  const _GuidelinesSearchBox({required this.controller});

  @override
  State<_GuidelinesSearchBox> createState() => _GuidelinesSearchBoxState();
}

class _GuidelinesSearchBoxState extends State<_GuidelinesSearchBox> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text: widget.controller.searchQuery,
    );
  }

  @override
  void didUpdateWidget(covariant _GuidelinesSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.controller.searchQuery;
    if (_textController.text != value) {
      _textController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    widget.controller.submitSearchQuery(value);
  }

  void _changeSearch(String value) {
    widget.controller.setSearchQuery(value);
  }

  void _clearSearch() {
    _textController.clear();
    widget.controller.submitSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final hasSearch = widget.controller.searchQuery.trim().isNotEmpty;
    return TextField(
      controller: _textController,
      textInputAction: TextInputAction.search,
      onChanged: _changeSearch,
      onSubmitted: _submitSearch,
      decoration: InputDecoration(
        hintText: 'Search guidelines, conditions, ICD codes...',
        prefixIcon: const Icon(LucideIcons.search),
        suffixIcon: hasSearch
            ? IconButton(
                onPressed: _clearSearch,
                icon: const Icon(LucideIcons.x),
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.primary),
        ),
      ),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  final GuidelinesController controller;

  const _QuickFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: LucideIcons.library,
            selected:
                !controller.hasPermanentFilter && !controller.hasActiveFilters,
            onTap: controller.showAllGuidelines,
          ),
          AppSpacing.sm.gap,
          _QuickFilterChip(
            label: 'High Priority',
            icon: LucideIcons.triangleAlert,
            selected: controller.showHighPriorityOnly,
            onTap: controller.toggleHighPriorityOnly,
          ),
          AppSpacing.sm.gap,
          _QuickFilterChip(
            label: 'Emergency',
            icon: LucideIcons.siren,
            selected: controller.isEmergencyRoute,
            onTap: controller.openEmergencyGuidelines,
          ),
          AppSpacing.sm.gap,
          _QuickFilterChip(
            label: 'Children',
            icon: LucideIcons.baby,
            selected: controller.selectedTargetPopulation
                .toLowerCase()
                .contains('children'),
            onTap: () => controller.setTargetPopulation('Children'),
          ),
          AppSpacing.sm.gap,
          _QuickFilterChip(
            label: 'Adults',
            icon: LucideIcons.user,
            selected: controller.selectedTargetPopulation
                .toLowerCase()
                .contains('adult'),
            onTap: () => controller.setTargetPopulation('Adults'),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _ActiveGuidelineContext extends StatelessWidget {
  final String title;
  final bool hasPermanentFilter;
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onShowAll;

  const _ActiveGuidelineContext({
    required this.title,
    required this.hasPermanentFilter,
    required this.hasFilters,
    required this.onClearFilters,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            hasPermanentFilter ? LucideIcons.folderOpen : LucideIcons.filter,
            size: 18,
            color: cs.primary,
          ),
          AppSpacing.sm.gap,
          Expanded(
            child: Text(
              hasPermanentFilter ? 'Showing: $title' : 'Filters applied',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasFilters)
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          if (hasPermanentFilter)
            TextButton(onPressed: onShowAll, child: const Text('Show all')),
        ],
      ),
    );
  }
}

class _GuidelinesEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasFilters;
  final bool hasPermanentFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onShowAll;

  const _GuidelinesEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hasFilters,
    required this.hasPermanentFilter,
    required this.onClearFilters,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.hPaddingMd + AppSpacing.vPaddingXl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PaginationIndicators.noItemsFound(
            title: title,
            subtitle: subtitle,
            icon: icon,
          ),
          if (hasFilters) ...[
            AppSpacing.md.gap,
            ElevatedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(LucideIcons.x),
              label: const Text('Clear filters'),
            ),
          ],
          if (hasPermanentFilter) ...[
            AppSpacing.sm.gap,
            TextButton.icon(
              onPressed: onShowAll,
              icon: const Icon(LucideIcons.listRestart),
              label: const Text('Show all guidelines'),
            ),
          ],
        ],
      ),
    );
  }
}
