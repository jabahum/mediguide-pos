import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/notifications/presentation/controllers/notifications_controller.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/my_notification_card.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    final controller = ref.read(notificationsControllerProvider.notifier);

    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.notifications.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          FilterButton(
            hasActiveFilters: state.hasActiveFilters,
            onPressed: () {
              _showFilterModal(context, ref);
            },
            onReset: state.hasActiveFilters ? controller.clearAllFilters : null,
          ),
          AppSpacing.xs.gap,
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refresh();
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
                child: _NotificationsHeaderCard(
                  hasFilters: state.hasActiveFilters,
                  selectedType: state.selectedType,
                  selectedPriority: state.selectedPriority,
                  onOpenFilters: () {
                    _showFilterModal(context, ref);
                  },
                  onClearFilters: controller.clearAllFilters,
                ),
              ),
            ),

            // =================================================
            // NOTIFICATIONS
            // =================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, MyNotification>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, MyNotification>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<MyNotification>(
                      itemBuilder: (context, notification, index) {
                        return _NotificationCardShell(
                          child: MyNotificationCard(
                            notification: notification,
                            onTap: () {
                              _handleTap(context, notification, controller);
                            },
                          ),
                        );
                      },

                      // =========================
                      // FIRST PAGE LOADING
                      // =========================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading notifications...',
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
                              'Unable to load notifications',
                          title: 'Failed to load notifications',
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
                          title: 'Failed to load more notifications',
                          icon: LucideIcons.bell,
                        );
                      },

                      // =========================
                      // EMPTY
                      // =========================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No notifications match filters',
                            description: 'Try adjusting your filters.',
                            actionLabel: 'Clear Filters',
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: 'No notifications found',
                          description:
                              'Notifications will appear here when available.',
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

  // =======================================================
  // NOTIFICATION TAP
  // =======================================================

  Future<void> _handleTap(
    BuildContext context,
    MyNotification notification,
    NotificationsController controller,
  ) async {
    try {
      await controller.markRead(notification);
    } catch (_) {
      // Mark-read failure should not prevent the user
      // from viewing the notification.
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${notification.title}\n'
            '${notification.message}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // =======================================================
  // FILTER MODAL
  // =======================================================

  Future<void> _showFilterModal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return const _NotificationFilterSheet();
      },
    );
  }
}

// =========================================================
// FILTER SHEET
// =========================================================

class _NotificationFilterSheet extends ConsumerWidget {
  const _NotificationFilterSheet();

  static const _typeOptions = [
    _NotificationFilterOption(label: 'All', value: ''),
    _NotificationFilterOption(label: 'Info', value: 'info'),
    _NotificationFilterOption(label: 'Success', value: 'success'),
    _NotificationFilterOption(label: 'Warning', value: 'warning'),
    _NotificationFilterOption(label: 'Error', value: 'error'),
  ];

  static const _priorityOptions = [
    _NotificationFilterOption(label: 'All', value: ''),
    _NotificationFilterOption(label: 'Low', value: 'low'),
    _NotificationFilterOption(label: 'Normal', value: 'normal'),
    _NotificationFilterOption(label: 'High', value: 'high'),
    _NotificationFilterOption(label: 'Urgent', value: 'urgent'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    final controller = ref.read(notificationsControllerProvider.notifier);

    final cs = context.theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =================================================
          // HEADER
          // =================================================
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.slidersHorizontal, color: cs.primary),
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

          // =================================================
          // TYPE
          // =================================================
          const _FilterSectionTitle(title: 'Type', icon: LucideIcons.bell),

          AppSpacing.sm.gap,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _typeOptions)
                _FilterChoiceChip(
                  label: option.label,
                  selected: state.selectedType == option.value,
                  onTap: () {
                    controller.setTypeFilter(option.value);
                  },
                ),
            ],
          ),

          AppSpacing.lg.gap,

          // =================================================
          // PRIORITY
          // =================================================
          const _FilterSectionTitle(
            title: 'Priority',
            icon: LucideIcons.triangleAlert,
          ),

          AppSpacing.sm.gap,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _priorityOptions)
                _FilterChoiceChip(
                  label: option.label,
                  selected: state.selectedPriority == option.value,
                  onTap: () {
                    controller.setPriorityFilter(option.value);
                  },
                ),
            ],
          ),

          AppSpacing.lg.gap,

          // =================================================
          // ACTIONS
          // =================================================
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.hasActiveFilters
                      ? () {
                          controller.clearAllFilters();

                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: const Icon(LucideIcons.x),
                  label: const Text('Clear'),
                ),
              ),

              AppSpacing.sm.gap,

              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(LucideIcons.check),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================
// HEADER
// =========================================================

class _NotificationsHeaderCard extends StatelessWidget {
  const _NotificationsHeaderCard({
    required this.hasFilters,
    required this.selectedType,
    required this.selectedPriority,
    required this.onOpenFilters,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final String selectedType;
  final String selectedPriority;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;

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
                          icon: LucideIcons.bell,
                          label: _formatFilterLabel(selectedType),
                          onClear: onClearFilters,
                        ),

                      if (selectedPriority.isNotEmpty)
                        _ActiveNotificationFilterChip(
                          icon: LucideIcons.triangleAlert,
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
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '';
    }

    return '${normalized[0].toUpperCase()}'
        '${normalized.substring(1).toLowerCase()}';
  }
}

// =========================================================
// ACTIVE FILTER CHIP
// =========================================================

class _ActiveNotificationFilterChip extends StatelessWidget {
  const _ActiveNotificationFilterChip({
    required this.icon,
    required this.label,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return InputChip(
      avatar: Icon(icon, size: 14, color: cs.primary),
      label: Text(label),
      onDeleted: onClear,
      deleteIcon: const Icon(LucideIcons.x, size: 14),
      backgroundColor: cs.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
      labelStyle: context.textTheme.labelSmall?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// =========================================================
// CARD SHELL
// =========================================================

class _NotificationCardShell extends StatelessWidget {
  const _NotificationCardShell({required this.child});

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
// FILTER SECTION TITLE
// =========================================================

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

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

// =========================================================
// FILTER CHIP
// =========================================================

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
// FILTER OPTION
// =========================================================

class _NotificationFilterOption {
  const _NotificationFilterOption({required this.label, required this.value});

  final String label;
  final String value;
}
