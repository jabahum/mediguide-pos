import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';
import 'package:user_app/features/support/presentation/controllers/help_center_controller.dart';
import 'package:user_app/features/support/presentation/widgets/create_ticket_dialog.dart';
import 'package:user_app/features/support/presentation/widgets/support_ticket_card.dart';

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
    final controller = ref.watch(helpCenterControllerProvider);
    return Scaffold(
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
            onPressed: () => controller.showFilterBottomSheet(context),
            tooltip: 'Filter tickets',
          ),
          AppSpacing.xs.gap,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateTicketDialog.show(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Ticket'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.refreshTickets(),
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
                child: _SupportHeaderCard(
                  onCreateTicket: () => CreateTicketDialog.show(context),
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
                child: _StatusFilterBar(
                  filters: _filters,
                  selectedValue: controller.selectedStatus,
                  onChanged: controller.updateStatusFilter,
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
              sliver: PagingListener(
                controller: controller.pagingController,
                builder: (context, state, fetchNextPage) =>
                    PagedSliverList<int, SupportTicket>.separated(
                      state: state,
                      fetchNextPage: fetchNextPage,
                      separatorBuilder: (context, index) => AppSpacing.sm.gap,
                      builderDelegate: PagedChildBuilderDelegate<SupportTicket>(
                        itemBuilder: (context, ticket, index) {
                          return SupportTicketCard(ticket: ticket);
                        },
                        firstPageErrorIndicatorBuilder: (context) =>
                            PaginationIndicators.firstPageError(
                              onRetry: fetchNextPage,
                              title: 'Failed to load tickets',
                              subtitle:
                                  'Please check your connection and try again',
                              icon: LucideIcons.messageCircle,
                            ),
                        newPageErrorIndicatorBuilder: (context) =>
                            PaginationIndicators.newPageError(
                              onRetry: fetchNextPage,
                              title: 'Error loading more tickets',
                              icon: LucideIcons.messageCircle,
                            ),
                        firstPageProgressIndicatorBuilder: (context) =>
                            PaginationIndicators.firstPageProgress(),
                        newPageProgressIndicatorBuilder: (context) =>
                            PaginationIndicators.newPageProgress(),
                        noItemsFoundIndicatorBuilder: (context) =>
                            _EmptySupportState(
                              onCreateTicket: () =>
                                  CreateTicketDialog.show(context),
                            ),
                        noMoreItemsIndicatorBuilder: (context) =>
                            PaginationIndicators.noMoreItems(),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportHeaderCard extends StatelessWidget {
  final VoidCallback onCreateTicket;

  const _SupportHeaderCard({required this.onCreateTicket});

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

class _StatusFilterBar extends StatelessWidget {
  final List<_TicketStatusFilter> filters;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _StatusFilterBar({
    required this.filters,
    required this.selectedValue,
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
          final selected = selectedValue == filter.value;

          return _StatusFilterChip(
            label: filter.label,
            icon: filter.icon,
            selected: selected,
            onTap: () {
              if (selectedValue == filter.value) return;
              onChanged(filter.value);
            },
          );
        },
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
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

class _EmptySupportState extends StatelessWidget {
  final VoidCallback onCreateTicket;

  const _EmptySupportState({required this.onCreateTicket});

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
            child: Icon(LucideIcons.messageCircle, color: cs.primary, size: 34),
          ),

          AppSpacing.md.gap,

          Text(
            AppTranslationKey.noSupportTicketsYet.tr,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            AppTranslationKey.createYourFirstSupportTicket.tr,
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          AppSpacing.lg.gap,

          FilledButton.icon(
            onPressed: onCreateTicket,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Create Ticket'),
          ),
        ],
      ),
    );
  }
}

class _TicketStatusFilter {
  final String label;
  final String value;
  final IconData icon;

  const _TicketStatusFilter({
    required this.label,
    required this.value,
    required this.icon,
  });
}
