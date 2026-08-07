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
    _TicketStatusFilter(label: 'Open', value: 'open', icon: LucideIcons.circle),
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

    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.mySupportCenter.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal),
            onPressed: () {
              controller.showFilterBottomSheet(context);
            },
            tooltip: 'Filter tickets',
          ),
          AppSpacing.xs.gap,
        ],
      ),

      // =====================================================
      // CREATE TICKET
      // =====================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          CreateTicketDialog.show(context);
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Ticket'),
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshTickets();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // =================================================
            // HEADER
            // =================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SupportHeaderCard(
                  hasFilters: state.hasActiveFilters,
                  onCreateTicket: () {
                    CreateTicketDialog.show(context);
                  },
                  onOpenFilters: () {
                    controller.showFilterBottomSheet(context);
                  },
                ),
              ),
            ),

            // =================================================
            // STATUS FILTER
            // =================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _StatusFilterBar(
                  filters: _filters,
                  selectedValue: state.selectedStatus,
                  onChanged: controller.updateStatusFilter,
                ),
              ),
            ),

            // =================================================
            // TICKET LIST
            // =================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, SupportTicket>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, SupportTicket>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<SupportTicket>(
                      itemBuilder: (context, ticket, index) {
                        return _SupportTicketShell(
                          child: SupportTicketCard(ticket: ticket),
                        );
                      },

                      // =========================
                      // FIRST PAGE LOADING
                      // =========================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading support tickets...',
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
                              'Unable to load support tickets',
                          onRetry: fetchNextPage,
                        );
                      },

                      // =========================
                      // NEXT PAGE ERROR
                      // =========================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'Error loading more tickets',
                          icon: LucideIcons.messageCircle,
                        );
                      },

                      // =========================
                      // EMPTY
                      // =========================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No tickets match your filters',
                            description:
                                'Try adjusting your search, status, priority or category.',
                            actionLabel: 'Clear Filters',
                            onAction: controller.clearFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: AppTranslationKey.noSupportTicketsYet.tr,
                          description:
                              AppTranslationKey.createYourFirstSupportTicket.tr,
                          actionLabel: 'Create Ticket',
                          onAction: () {
                            CreateTicketDialog.show(context);
                          },
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

// =========================================================
// HEADER
// =========================================================

class _SupportHeaderCard extends StatelessWidget {
  const _SupportHeaderCard({
    required this.hasFilters,
    required this.onCreateTicket,
    required this.onOpenFilters,
  });

  final bool hasFilters;
  final VoidCallback onCreateTicket;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(LucideIcons.headphones, color: cs.primary, size: 28),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.mySupportCenter.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Track your support requests and create a new ticket when you need help.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                if (hasFilters) ...[
                  const SizedBox(height: 10),
                  InputChip(
                    avatar: Icon(
                      LucideIcons.filter,
                      size: 14,
                      color: cs.primary,
                    ),
                    label: const Text('Filters active'),
                    onPressed: onOpenFilters,
                    backgroundColor: cs.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    labelStyle: context.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          AppSpacing.sm.gap,

          IconButton.filled(
            onPressed: onCreateTicket,
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Create ticket',
          ),
        ],
      ),
    );
  }
}

// =========================================================
// STATUS FILTER BAR
// =========================================================

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

// =========================================================
// STATUS FILTER CHIP
// =========================================================

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
    final cs = context.theme.colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        onTap();
      },
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

// =========================================================
// TICKET SHELL
// =========================================================

class _SupportTicketShell extends StatelessWidget {
  const _SupportTicketShell({required this.child});

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

// =========================================================
// FILTER MODEL
// =========================================================

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
