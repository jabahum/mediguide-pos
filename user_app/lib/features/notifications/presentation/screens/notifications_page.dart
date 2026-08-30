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

part '../widgets/notifications_page_notification_filter_sheet.dart';
part '../widgets/notifications_page_notification_browse_card.dart';
part '../widgets/notifications_page_active_notification_filters.dart';
part '../widgets/notifications_page_active_notification_filter_chip.dart';
part '../widgets/notifications_page_notification_card_shell.dart';
part '../widgets/notifications_page_filter_section_title.dart';
part '../widgets/notifications_page_filter_choice_chip.dart';
part '../widgets/notifications_page_notification_filter_option.dart';

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
      await controller.recordOpen(notification);
    } catch (_) {}
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
      try {
        await controller.recordClick(notification);
      } catch (_) {}
      if (!context.mounted) return;
      context.push(location);
      return;
    }

    // =======================================================================
    // EXTERNAL ROUTE
    // =======================================================================

    if (target?.externalUri case final uri?) {
      try {
        await controller.recordClick(notification);
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
