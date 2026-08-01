import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/modules/notifications_module/notifications_controller.dart';
import '../../data/models/models.dart';
import '../../translations/app_translations.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_button.dart';
import '../../widgets/my_notification_card.dart';
import '../../widgets/pagination_indicators.dart';

class NotificationsPage extends GetWidget<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.notifications.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Obx(
            () => FilterButton(
              hasActiveFilters: controller.hasActiveFilters.value,
              onPressed: () => _showFilterModal(context),
              onReset: controller.hasActiveFilters.value
                  ? controller.clearAllFilters
                  : null,
            ),
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
                child: Obx(
                  () => _NotificationsHeaderCard(
                    hasFilters: controller.hasActiveFilters.value,
                    selectedType: controller.selectedType.value,
                    selectedPriority: controller.selectedPriority.value,
                    onOpenFilters: () => _showFilterModal(context),
                    onClearFilters: controller.clearAllFilters,
                  ),
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
              sliver: PagingListener<int, MyNotification>(
                controller: controller.pagingController,
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, MyNotification>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<MyNotification>(
                      itemBuilder: (context, notification, index) {
                        return _NotificationCardShell(
                          child: MyNotificationCard(
                            notification: notification,
                            onTap: () => _handleTap(notification),
                          ),
                        );
                      },
                      firstPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageError(
                            onRetry: fetchNextPage,
                            title: 'Failed to load notifications',
                            subtitle:
                                'Please check your connection and try again',
                            icon: LucideIcons.bell,
                          ),
                      newPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageError(
                            onRetry: fetchNextPage,
                            title: 'Failed to load more notifications',
                            icon: LucideIcons.bell,
                          ),
                      firstPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageProgress(),
                      newPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageProgress(),
                      noItemsFoundIndicatorBuilder: (context) {
                        return Obx(() {
                          final isFiltered = controller.hasActiveFilters.value;

                          return _EmptyNotificationsState(
                            isFiltered: isFiltered,
                            onClearFilters: controller.clearAllFilters,
                          );
                        });
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
      backgroundColor: cs.surface,
    );
  }

  void _handleTap(MyNotification notification) {
    controller.markRead(notification).catchError((_) {});
    Get.snackbar(
      notification.title,
      notification.message,
      duration: const Duration(seconds: 3),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.slidersHorizontal,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                    AppSpacing.md.gap,
                    Expanded(
                      child: Text(
                        'Filter Notifications',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                AppSpacing.lg.gap,

                _FilterSectionTitle(title: 'Type', icon: LucideIcons.bell),

                AppSpacing.sm.gap,

                Obx(() {
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children:
                        const [
                          _NotificationFilterOption(label: 'All', value: ''),
                          _NotificationFilterOption(
                            label: 'Info',
                            value: 'info',
                          ),
                          _NotificationFilterOption(
                            label: 'Success',
                            value: 'success',
                          ),
                          _NotificationFilterOption(
                            label: 'Warning',
                            value: 'warning',
                          ),
                          _NotificationFilterOption(
                            label: 'Error',
                            value: 'error',
                          ),
                        ].map((option) {
                          return _FilterChoiceChip(
                            label: option.label,
                            selected:
                                controller.selectedType.value == option.value,
                            onTap: () => controller.setTypeFilter(option.value),
                          );
                        }).toList(),
                  );
                }),

                AppSpacing.lg.gap,

                _FilterSectionTitle(
                  title: 'Priority',
                  icon: LucideIcons.triangleAlert,
                ),

                AppSpacing.sm.gap,

                Obx(() {
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children:
                        const [
                          _NotificationFilterOption(label: 'All', value: ''),
                          _NotificationFilterOption(label: 'Low', value: 'low'),
                          _NotificationFilterOption(
                            label: 'Normal',
                            value: 'normal',
                          ),
                          _NotificationFilterOption(
                            label: 'High',
                            value: 'high',
                          ),
                          _NotificationFilterOption(
                            label: 'Urgent',
                            value: 'urgent',
                          ),
                        ].map((option) {
                          return _FilterChoiceChip(
                            label: option.label,
                            selected:
                                controller.selectedPriority.value ==
                                option.value,
                            onTap: () =>
                                controller.setPriorityFilter(option.value),
                          );
                        }).toList(),
                  );
                }),

                AppSpacing.lg.gap,

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          controller.clearAllFilters();
                          Navigator.pop(context);
                        },
                        icon: const Icon(LucideIcons.x),
                        label: const Text('Clear'),
                      ),
                    ),
                    AppSpacing.sm.gap,
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.check),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationsHeaderCard extends StatelessWidget {
  final bool hasFilters;
  final String selectedType;
  final String selectedPriority;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;

  const _NotificationsHeaderCard({
    required this.hasFilters,
    required this.selectedType,
    required this.selectedPriority,
    required this.onOpenFilters,
    required this.onClearFilters,
  });

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
            child: Icon(LucideIcons.bell, color: cs.primary, size: 28),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.notifications.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay updated with alerts, reminders and important system messages.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (selectedType.isNotEmpty)
                        _ActiveNotificationFilterChip(
                          label: _formatFilterLabel(selectedType),
                          onClear: onClearFilters,
                        ),
                      if (selectedPriority.isNotEmpty)
                        _ActiveNotificationFilterChip(
                          label: _formatFilterLabel(selectedPriority),
                          onClear: onClearFilters,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          AppSpacing.sm.gap,

          IconButton.filledTonal(
            onPressed: onOpenFilters,
            icon: const Icon(LucideIcons.slidersHorizontal),
            tooltip: 'Filter notifications',
          ),
        ],
      ),
    );
  }

  String _formatFilterLabel(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    final lower = value.trim().toLowerCase();

    return lower[0].toUpperCase() + lower.substring(1);
  }
}

class _ActiveNotificationFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _ActiveNotificationFilterChip({
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Icon(LucideIcons.x, size: 13, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _NotificationCardShell extends StatelessWidget {
  final Widget child;

  const _NotificationCardShell({required this.child});

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

class _EmptyNotificationsState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onClearFilters;

  const _EmptyNotificationsState({
    required this.isFiltered,
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
              isFiltered ? LucideIcons.searchX : LucideIcons.bell,
              color: cs.primary,
              size: 36,
            ),
          ),

          AppSpacing.md.gap,

          Text(
            isFiltered
                ? 'No notifications match filters'
                : 'No notifications found',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            isFiltered
                ? 'Try adjusting your search or filters.'
                : 'Notifications will appear here when available.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          if (isFiltered) ...[
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

class _FilterSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FilterSectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
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

class _NotificationFilterOption {
  final String label;
  final String value;

  const _NotificationFilterOption({required this.label, required this.value});
}
