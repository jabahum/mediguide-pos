import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/ministry_directory.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_button.dart';
import '../../widgets/ministry_directory_card.dart';
import '../../widgets/pagination_indicators.dart';
import 'ministry_directory_controller.dart';

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
        if (mounted) {
          ref
              .read(ministryDirectoryControllerProvider)
              .applyTreeFilters(filters);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(ministryDirectoryControllerProvider);
    final cs = context.theme.colorScheme;

    return Scaffold(
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
            hasActiveFilters: controller.hasActiveFilters,
            onPressed: () => controller.showAdvancedFilter(context),
            onReset: controller.hasActiveFilters
                ? controller.resetFilters
                : null,
            tooltip: 'filterDirectory'.tr,
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
                child: _DirectoryHeaderCard(
                  onOpenFilters: () => controller.showAdvancedFilter(context),
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
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, MinistryDirectory>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate:
                        PagedChildBuilderDelegate<MinistryDirectory>(
                          itemBuilder: (context, entry, index) {
                            return _DirectoryCardShell(
                              child: MinistryDirectoryCard(
                                entry: entry,
                                index: index,
                              ),
                            );
                          },

                          // ================= ERROR STATES =================
                          firstPageErrorIndicatorBuilder: (context) =>
                              PaginationIndicators.firstPageError(
                                onRetry: fetchNextPage,
                                title: 'Failed to load directory',
                                subtitle:
                                    'Please check your connection and try again',
                                icon: LucideIcons.phone,
                              ),

                          newPageErrorIndicatorBuilder: (context) =>
                              PaginationIndicators.newPageError(
                                onRetry: fetchNextPage,
                                title: 'Failed to load more entries',
                                icon: LucideIcons.phone,
                              ),

                          // ================= LOADING STATES =================
                          firstPageProgressIndicatorBuilder: (context) =>
                              PaginationIndicators.firstPageProgress(),

                          newPageProgressIndicatorBuilder: (context) =>
                              PaginationIndicators.newPageProgress(),

                          // ================= EMPTY STATE =================
                          noItemsFoundIndicatorBuilder: (context) {
                            final hasFilters = controller.hasActiveFilters;

                            return _EmptyDirectoryState(
                              hasFilters: hasFilters,
                              onClearFilters: controller.resetFilters,
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

class _DirectoryHeaderCard extends StatelessWidget {
  final VoidCallback onOpenFilters;

  const _DirectoryHeaderCard({required this.onOpenFilters});

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
  final Widget child;

  const _DirectoryCardShell({required this.child});

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

class _EmptyDirectoryState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyDirectoryState({
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
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              hasFilters ? LucideIcons.searchX : LucideIcons.phone,
              color: cs.primary,
              size: 36,
            ),
          ),

          AppSpacing.md.gap,

          Text(
            hasFilters
                ? 'No entries match your filters'
                : 'No directory entries found',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            hasFilters
                ? 'Try adjusting your search or filters.'
                : 'Directory entries will appear here when available.',
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
              label: Text('clearFilters'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
