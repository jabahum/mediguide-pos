import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/support/presentation/controllers/help_center_controller.dart';
import 'package:user_app/features/support/presentation/widgets/create_ticket_dialog.dart';
import 'package:user_app/features/support/presentation/widgets/support_ticket_card.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  static const List<_TicketStatusFilter> _filters = [
    _TicketStatusFilter(label: 'All', value: 'all', icon: LucideIcons.inbox),
    _TicketStatusFilter(
      label: 'Open',
      value: 'open',
      icon: LucideIcons.circleDot,
    ),
    _TicketStatusFilter(
      label: 'In Progress',
      value: 'inProgress',
      icon: LucideIcons.loaderCircle,
    ),
    _TicketStatusFilter(
      label: 'Resolved',
      value: 'resolved',
      icon: LucideIcons.circleCheck,
    ),
    _TicketStatusFilter(
      label: 'Closed',
      value: 'closed',
      icon: LucideIcons.lock,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(helpCenterControllerProvider);

    final controller = ref.read(helpCenterControllerProvider.notifier);

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
              AppTranslationKey.mySupportCenter.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Support requests and assistance',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Filter tickets',
            onPressed: () {
              controller.showFilterBottomSheet(context);
            },
            icon: Badge(
              isLabelVisible: state.hasActiveFilters,
              child: const Icon(LucideIcons.slidersHorizontal),
            ),
          ),
          AppSpacing.hGapXs,
        ],
      ),

      // =====================================================================
      // NEW TICKET
      // =====================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          CreateTicketDialog.show(context);
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Ticket'),
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshTickets();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // SUPPORT INTRO
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
                    _SupportBrowseCard(
                      hasFilters: state.hasActiveFilters,
                      onCreateTicket: () {
                        CreateTicketDialog.show(context);
                      },
                      onOpenFilters: () {
                        controller.showFilterBottomSheet(context);
                      },
                    ),

                    if (state.hasActiveFilters) ...[
                      AppSpacing.gapMd,

                      _ActiveSupportFilters(
                        onEdit: () {
                          controller.showFilterBottomSheet(context);
                        },
                        onClear: controller.clearFilters,
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      'Ticket status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Quickly switch between open, active and completed requests.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    AppSpacing.gapSm,

                    _StatusFilterBar(
                      filters: _filters,
                      selectedValue: state.selectedStatus,
                      onChanged: controller.updateStatusFilter,
                    ),

                    AppSpacing.gapLg,

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _sectionTitle(
                              state.selectedStatus,
                              state.hasActiveFilters,
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),

                        if (state.hasActiveFilters)
                          TextButton.icon(
                            onPressed: controller.clearFilters,
                            icon: const Icon(LucideIcons.rotateCcw, size: 16),
                            label: const Text('Reset'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _sectionSubtitle(
                        state.selectedStatus,
                        state.hasActiveFilters,
                      ),
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
            // TICKET LIST
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, SupportTicket>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, SupportTicket>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<SupportTicket>(
                      // =====================================================
                      // ITEM
                      // =====================================================
                      itemBuilder: (context, ticket, index) {
                        return _SupportTicketShell(
                          child: SupportTicketCard(ticket: ticket),
                        );
                      },

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading support tickets...',
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
                              'Unable to load support tickets',
                          title: 'Unable to load support requests',
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
                          title: 'Error loading more tickets',
                          icon: LucideIcons.messageCircle,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No tickets match your filters',
                            description:
                                'Try adjusting the status, priority, category or search filters.',
                            actionLabel: 'Clear filters',
                            onAction: controller.clearFilters,
                          );
                        }

                        if (state.selectedStatus != 'all' &&
                            state.selectedStatus.trim().isNotEmpty) {
                          return EmptyState.noResults(
                            title:
                                'No ${_statusLabel(state.selectedStatus).toLowerCase()} tickets',
                            description:
                                'You currently have no support tickets with this status.',
                            actionLabel: 'Show all tickets',
                            onAction: () {
                              controller.updateStatusFilter('all');
                            },
                          );
                        }

                        return EmptyState.noData(
                          title: AppTranslationKey.noSupportTicketsYet.tr,
                          description:
                              AppTranslationKey.createYourFirstSupportTicket.tr,
                          actionLabel: 'Create ticket',
                          onAction: () {
                            CreateTicketDialog.show(context);
                          },
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

  static String _sectionTitle(String selectedStatus, bool hasActiveFilters) {
    if (hasActiveFilters) {
      return 'Matching tickets';
    }

    return switch (selectedStatus) {
      'open' => 'Open tickets',
      'inProgress' => 'Tickets in progress',
      'resolved' => 'Resolved tickets',
      'closed' => 'Closed tickets',
      _ => 'Recent tickets',
    };
  }

  static String _sectionSubtitle(String selectedStatus, bool hasActiveFilters) {
    if (hasActiveFilters) {
      return 'Showing support requests matching your current filters.';
    }

    return switch (selectedStatus) {
      'open' => 'Requests waiting for review or action.',
      'inProgress' => 'Requests currently being worked on.',
      'resolved' => 'Requests where a resolution has been provided.',
      'closed' => 'Completed support requests.',
      _ => 'Track your recent support requests and responses.',
    };
  }
}

// ===========================================================================
// SUPPORT BROWSE CARD
// ===========================================================================

class _SupportBrowseCard extends StatelessWidget {
  const _SupportBrowseCard({
    required this.hasFilters,
    required this.onCreateTicket,
    required this.onOpenFilters,
  });

  final bool hasFilters;
  final VoidCallback onCreateTicket;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
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
              LucideIcons.headphones,
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
                  'How can we help?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 3),

                Text(
                  hasFilters
                      ? 'Filters are active. You can adjust them or submit a new support request.'
                      : 'Create a support ticket when you need technical or account assistance.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                AppSpacing.gapMd,

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onCreateTicket,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Create ticket'),
                    ),

                    OutlinedButton.icon(
                      onPressed: onOpenFilters,
                      icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
                      label: const Text('Filter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ACTIVE FILTERS
// ===========================================================================

class _ActiveSupportFilters extends StatelessWidget {
  const _ActiveSupportFilters({required this.onEdit, required this.onClear});

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
            size: 17,
            color: colors.onSecondaryContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              'Additional ticket filters applied',
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
// STATUS FILTER BAR
// ===========================================================================

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.filters,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<_TicketStatusFilter> filters;
  final String selectedValue;
  final ValueChanged<String> onChanged;

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

          final selected = selectedValue == filter.value;

          return _StatusFilterChip(
            label: filter.label,
            icon: filter.icon,
            selected: selected,
            onTap: () {
              if (selected) {
                return;
              }

              onChanged(filter.value);
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// STATUS FILTER CHIP
// ===========================================================================

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        onTap();
      },
      avatar: Icon(
        icon,
        size: 15,
        color: selected ? colors.onPrimary : colors.primary,
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? colors.onPrimary : colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceContainerLowest,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

// ===========================================================================
// TICKET SHELL
// ===========================================================================

class _SupportTicketShell extends StatelessWidget {
  const _SupportTicketShell({required this.child});

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

// ===========================================================================
// FILTER MODEL
// ===========================================================================

class _TicketStatusFilter {
  const _TicketStatusFilter({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

// ===========================================================================
// HELPERS
// ===========================================================================

String _statusLabel(String value) {
  return switch (value) {
    'open' => 'Open',
    'inProgress' => 'In Progress',
    'resolved' => 'Resolved',
    'closed' => 'Closed',
    _ => 'All',
  };
}
