import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/notifications/domain/notification_action_resolver.dart';
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
              AppTranslationKey.notifications.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Alerts, reminders and updates',
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
              _showFilterModal(context, ref);
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
          controller.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // FILTER CONTEXT
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
                    _NotificationBrowseCard(
                      hasActiveFilters: state.hasActiveFilters,
                      onOpenFilters: () {
                        _showFilterModal(context, ref);
                      },
                    ),

                    if (state.hasActiveFilters) ...[
                      AppSpacing.gapMd,

                      _ActiveNotificationFilters(
                        selectedType: state.selectedType,
                        selectedPriority: state.selectedPriority,
                        onClearType: () {
                          controller.setTypeFilter('');
                        },
                        onClearPriority: () {
                          controller.setPriorityFilter('');
                        },
                        onEdit: () {
                          _showFilterModal(context, ref);
                        },
                        onClearAll: controller.clearAllFilters,
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      state.hasActiveFilters
                          ? 'Matching notifications'
                          : 'Recent notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      state.hasActiveFilters
                          ? 'Showing alerts matching your current filters.'
                          : 'Review important messages and system updates.',
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
            // NOTIFICATIONS
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, MyNotification>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, MyNotification>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<MyNotification>(
                      // =====================================================
                      // ITEM
                      // =====================================================
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

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading notifications...',
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
                              'Unable to load notifications',
                          title: 'Failed to load notifications',
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
                          title: 'Failed to load more notifications',
                          icon: LucideIcons.bell,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No notifications match filters',
                            description:
                                'Try adjusting your type or priority filters.',
                            actionLabel: 'Clear filters',
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: 'No notifications found',
                          description:
                              'Notifications will appear here when available.',
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

  // =========================================================================
  // NOTIFICATION TAP
  // =========================================================================

  Future<void> _handleTap(
    BuildContext context,
    MyNotification notification,
    NotificationsController controller,
  ) async {
    try {
      await controller.markRead(notification);
    } catch (_) {
      // Reading the notification should not depend on
      // the read-state update succeeding.
    }

    if (!context.mounted) {
      return;
    }

    final target = NotificationActionResolver.resolve(
      action: notification.action,
      legacyActionUrl: notification.actionUrl,
    );

    // =======================================================================
    // INTERNAL ROUTE
    // =======================================================================

    if (target?.location case final location?) {
      context.push(location);
      return;
    }

    // =======================================================================
    // EXTERNAL ROUTE
    // =======================================================================

    if (target?.externalUri case final uri?) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && context.mounted) {
          _showNotificationMessage(
            context,
            'Unable to open this notification link.',
          );
        }
      } catch (_) {
        if (context.mounted) {
          _showNotificationMessage(
            context,
            'Unable to open this notification link.',
          );
        }
      }

      return;
    }

    // =======================================================================
    // NO ACTION
    // =======================================================================

    if (!context.mounted) {
      return;
    }

    _showNotificationDetails(context, notification);
  }

  void _showNotificationDetails(
    BuildContext context,
    MyNotification notification,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        sheetContext,
                      ).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.bell,
                      color: Theme.of(sheetContext).colorScheme.primary,
                      size: 20,
                    ),
                  ),

                  AppSpacing.hGapMd,

                  Expanded(
                    child: Text(
                      notification.title,
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              AppSpacing.gapMd,

              Text(
                notification.message,
                style: Theme.of(
                  sheetContext,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),

              AppSpacing.gapLg,

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // =========================================================================
  // FILTER MODAL
  // =========================================================================

  Future<void> _showFilterModal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return const _NotificationFilterSheet();
      },
    );
  }
}

// ===========================================================================
// FILTER SHEET
// ===========================================================================

class _NotificationFilterSheet extends ConsumerWidget {
  const _NotificationFilterSheet();

  static const _typeOptions = [
    _NotificationFilterOption(
      label: 'All',
      value: '',
      icon: LucideIcons.layers,
    ),
    _NotificationFilterOption(
      label: 'Info',
      value: 'info',
      icon: LucideIcons.info,
    ),
    _NotificationFilterOption(
      label: 'Success',
      value: 'success',
      icon: LucideIcons.circleCheck,
    ),
    _NotificationFilterOption(
      label: 'Warning',
      value: 'warning',
      icon: LucideIcons.triangleAlert,
    ),
    _NotificationFilterOption(
      label: 'Error',
      value: 'error',
      icon: LucideIcons.circleX,
    ),
  ];

  static const _priorityOptions = [
    _NotificationFilterOption(
      label: 'All',
      value: '',
      icon: LucideIcons.layers,
    ),
    _NotificationFilterOption(
      label: 'Low',
      value: 'low',
      icon: LucideIcons.arrowDown,
    ),
    _NotificationFilterOption(
      label: 'Normal',
      value: 'normal',
      icon: LucideIcons.minus,
    ),
    _NotificationFilterOption(
      label: 'High',
      value: 'high',
      icon: LucideIcons.arrowUp,
    ),
    _NotificationFilterOption(
      label: 'Urgent',
      value: 'urgent',
      icon: LucideIcons.siren,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    final controller = ref.read(notificationsControllerProvider.notifier);

    final colors = Theme.of(context).colorScheme;

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
          // =================================================================
          // HEADER
          // =================================================================
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  color: colors.primary,
                  size: 20,
                ),
              ),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Narrow alerts by type and priority.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.gapLg,

          // =================================================================
          // TYPE
          // =================================================================
          const _FilterSectionTitle(title: 'Type', icon: LucideIcons.bell),

          AppSpacing.gapSm,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _typeOptions)
                _FilterChoiceChip(
                  label: option.label,
                  icon: option.icon,
                  selected: state.selectedType == option.value,
                  onTap: () {
                    controller.setTypeFilter(option.value);
                  },
                ),
            ],
          ),

          AppSpacing.gapLg,

          // =================================================================
          // PRIORITY
          // =================================================================
          const _FilterSectionTitle(
            title: 'Priority',
            icon: LucideIcons.triangleAlert,
          ),

          AppSpacing.gapSm,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _priorityOptions)
                _FilterChoiceChip(
                  label: option.label,
                  icon: option.icon,
                  selected: state.selectedPriority == option.value,
                  onTap: () {
                    controller.setPriorityFilter(option.value);
                  },
                ),
            ],
          ),

          AppSpacing.gapLg,

          // =================================================================
          // ACTIONS
          // =================================================================
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
                  icon: const Icon(LucideIcons.rotateCcw),
                  label: const Text('Reset'),
                ),
              ),

              AppSpacing.hGapSm,

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

// ===========================================================================
// BROWSE CARD
// ===========================================================================

class _NotificationBrowseCard extends StatelessWidget {
  const _NotificationBrowseCard({
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
                  LucideIcons.bellRing,
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
                      'Filter notifications',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasActiveFilters
                          ? 'Filters are applied. Tap to adjust them.'
                          : 'Filter alerts by type or priority.',
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

class _ActiveNotificationFilters extends StatelessWidget {
  const _ActiveNotificationFilters({
    required this.selectedType,
    required this.selectedPriority,
    required this.onClearType,
    required this.onClearPriority,
    required this.onEdit,
    required this.onClearAll,
  });

  final String selectedType;
  final String selectedPriority;

  final VoidCallback onClearType;
  final VoidCallback onClearPriority;
  final VoidCallback onEdit;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.listFilter,
                size: 17,
                color: colors.onSecondaryContainer,
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  'Notification filters',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              TextButton(onPressed: onEdit, child: const Text('Edit')),

              TextButton(onPressed: onClearAll, child: const Text('Clear all')),
            ],
          ),

          if (selectedType.isNotEmpty || selectedPriority.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (selectedType.isNotEmpty)
                    _ActiveNotificationFilterChip(
                      icon: LucideIcons.bell,
                      label: _formatFilterLabel(selectedType),
                      onClear: onClearType,
                    ),

                  if (selectedPriority.isNotEmpty)
                    _ActiveNotificationFilterChip(
                      icon: LucideIcons.triangleAlert,
                      label: _formatFilterLabel(selectedPriority),
                      onClear: onClearPriority,
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
// ACTIVE CHIP
// ===========================================================================

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
    final colors = Theme.of(context).colorScheme;

    return InputChip(
      avatar: Icon(icon, size: 14, color: colors.onSecondaryContainer),
      label: Text(label),
      onDeleted: onClear,
      deleteIcon: const Icon(LucideIcons.x, size: 14),
      backgroundColor: colors.surface.withValues(alpha: 0.65),
      side: BorderSide.none,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ===========================================================================
// CARD SHELL
// ===========================================================================

class _NotificationCardShell extends StatelessWidget {
  const _NotificationCardShell({required this.child});

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
// FILTER SECTION TITLE
// ===========================================================================

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        AppSpacing.hGapSm,
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ===========================================================================
// FILTER CHIP
// ===========================================================================

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
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
// FILTER OPTION
// ===========================================================================

class _NotificationFilterOption {
  const _NotificationFilterOption({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

String _formatFilterLabel(String value) {
  final normalized = value.trim();

  if (normalized.isEmpty) {
    return '';
  }

  return '${normalized[0].toUpperCase()}'
      '${normalized.substring(1).toLowerCase()}';
}
