import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/date_utils.dart';
import 'package:user_app/core/utils/responsive.dart';

import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_state.dart';
import 'package:user_app/app/providers/app_providers.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/section_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.greetingHour})
    : assert(greetingHour == null || (greetingHour >= 0 && greetingHour <= 23));

  /// Overrides the local clock for previews/tests.
  final int? greetingHour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    final home = ref.watch(homeControllerProvider);

    final data = home.valueOrNull ?? const HomeState();

    final controller = ref.read(homeControllerProvider.notifier);

    final user = ref.watch(
      authControllerProvider.select((value) => value.valueOrNull?.user),
    );

    final userName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Healthcare Professional';

    final professionalContext = <String>[
      if (user?.jobTitle.trim().isNotEmpty == true)
        user!.jobTitle.trim()
      else if (user?.role != null)
        user!.role!.label,
      if (user?.organization.trim().isNotEmpty == true)
        user!.organization.trim(),
    ].join(' · ');

    final greeting = _greetingFor(greetingHour ?? DateTime.now().hour);
    final notificationUnreadCount =
        ref.watch(notificationUnreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: _HomeAppBar(
        greeting: greeting,
        userName: userName,
        professionalContext: professionalContext,
        notificationUnreadCount: notificationUnreadCount,
        onNotifications: () {
          AppNavigator.push(AppRoutes.notifications);
        },
      ),

      floatingActionButton: _ChatFloatingButton(
        unreadCount: data.unreadMessagesCount,
        onPressed: () {
          AppNavigator.push(AppRoutes.chatList);
        },
      ),

      body: _buildBody(
        context: context,
        ref: ref,
        home: home,
        data: data,
        controller: controller,
      ),
    );
  }

  static String _greetingFor(int hour) {
    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<HomeState> home,
    required HomeState data,
    required HomeController controller,
  }) {
    // ---------------------------------------------------------
    // Initial loading
    // ---------------------------------------------------------

    if (home.isLoading && !data.hasContent) {
      return const AppLoadingView(message: 'Loading MediGuide...');
    }

    // ---------------------------------------------------------
    // Initial error
    // ---------------------------------------------------------

    if (home.hasError && !data.hasContent) {
      return AppErrorView(
        error: home.error ?? 'Unable to load home content',
        onRetry: controller.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.responsiveHorizontalPadding,
          AppSpacing.md,
          context.responsiveHorizontalPadding,
          AppSpacing.xxxl,
        ),
        children: [
          // ---------------------------------------------------
          // Background refresh
          // ---------------------------------------------------
          if (home.isLoading && data.hasContent) ...[
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: LinearProgressIndicator(minHeight: 3),
            ),
            AppSpacing.md.gap,
          ],

          // ---------------------------------------------------
          // Search
          // ---------------------------------------------------
          _ClinicalSearchCard(
            onTap: () {
              AppNavigator.push(AppRoutes.search);
            },
          ),

          AppSpacing.lg.gap,

          // ---------------------------------------------------
          // Quick actions
          // ---------------------------------------------------
          SectionHeader(title: 'Quick access'),

          AppSpacing.sm.gap,

          _QuickActionGrid(
            actions: [
              _HomeQuickAction(
                icon: LucideIcons.bookOpenText,
                title: 'Guidelines',
                subtitle: 'Clinical guidance',
                onTap: () async {
                  await AppNavigator.push(AppRoutes.publicGuidelines);
                },
              ),

              _HomeQuickAction(
                icon: LucideIcons.pill,
                title: 'Drug Index',
                subtitle: 'Medicines reference',
                onTap: () async {
                  await AppNavigator.push(AppRoutes.drugIndex);
                },
              ),

              _HomeQuickAction(
                icon: LucideIcons.calculator,
                title: 'Calculators',
                subtitle: 'Clinical tools',
                onTap: () async {
                  await AppNavigator.push(
                    AppRoutes.tools,
                    extra: const {'initialTab': 1},
                  );
                },
              ),

              _HomeQuickAction(
                icon: LucideIcons.hospital,
                title: 'Facilities',
                subtitle: 'Find health services',
                onTap: () async {
                  await AppNavigator.push(AppRoutes.healthFacilities);
                },
              ),
            ],
          ),

          AppSpacing.xl.gap,

          // ---------------------------------------------------
          // Continue reading
          // ---------------------------------------------------
          if (data.continueReadingItems.isNotEmpty) ...[
            SectionHeader(
              title: 'Continue reading',
              onSeeAll: () {
                AppNavigator.push(AppRoutes.library);
              },
            ),

            AppSpacing.sm.gap,

            _ContinueReadingSection(
              items: data.continueReadingItems.take(3).toList(growable: false),
              onOpen: (progress) {
                _continueReading(ref, progress);
              },
            ),

            AppSpacing.xl.gap,
          ],

          // ---------------------------------------------------
          // Recent guideline updates
          // ---------------------------------------------------
          SectionHeader(title: 'Recent updates', onSeeAll: _openAllGuidelines),

          AppSpacing.sm.gap,

          if (data.recentlyUpdatedGuidelines.isNotEmpty)
            _GuidelinesPreviewList(
              guidelines: data.recentlyUpdatedGuidelines
                  .take(4)
                  .toList(growable: false),
              onOpenGuideline: (guideline) {
                _openGuideline(ref, guideline);
              },
            )
          else
            _NoRecentGuidelinesCard(onBrowse: _openAllGuidelines),

          // ---------------------------------------------------
          // Completely empty
          // ---------------------------------------------------
          if (!data.hasContent && data.recentlyUpdatedGuidelines.isEmpty) ...[
            AppSpacing.xl.gap,

            EmptyState.noData(
              title: 'No content available',
              description:
                  'Clinical guidelines and tools will appear here when available.',
              actionLabel: 'Refresh',
              onAction: () {
                controller.refresh();
              },
            ),
          ],
        ],
      ),
    );
  }

  static void _openAllGuidelines() {
    AppNavigator.push(AppRoutes.publicGuidelines);
  }

  static Future<void> _openGuideline(
    WidgetRef ref,
    GuidelinePublication guideline,
  ) async {
    await AppNavigator.push(AppRoutes.publicGuideline(guideline.id));

    ref.invalidate(homeControllerProvider);
  }

  static Future<void> _continueReading(
    WidgetRef ref,
    ReadingProgress progress,
  ) async {
    final guidelineId = progress.guidelineId.trim();

    if (guidelineId.isEmpty) {
      return;
    }

    try {
      final section = progress.currentSection.trim();

      final location = AppRoutes.readPublicGuideline(guidelineId);

      await AppNavigator.push(
        section.isEmpty
            ? location
            : '$location?section=${Uri.encodeQueryComponent(section)}',
      );

      ref.invalidate(homeControllerProvider);
    } catch (_) {
      //
      // Keep the existing home state.
      //
      // A temporary offline/navigation failure
      // should not remove continue-reading data.
      //
    }
  }
}

/// ===========================================================================
/// APP BAR
/// ===========================================================================

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({
    required this.greeting,
    required this.userName,
    required this.professionalContext,
    required this.notificationUnreadCount,
    required this.onNotifications,
  });

  final String greeting;
  final String userName;
  final String professionalContext;
  final int notificationUnreadCount;
  final VoidCallback onNotifications;

  @override
  Size get preferredSize =>
      Size.fromHeight(professionalContext.isEmpty ? 76 : 94);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: AppSpacing.md,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),

          if (professionalContext.isNotEmpty) ...[
            const SizedBox(height: 1),

            Text(
              professionalContext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: notificationUnreadCount > 0,
              label: Text(
                notificationUnreadCount > 99
                    ? '99+'
                    : '$notificationUnreadCount',
              ),
              child: const Icon(LucideIcons.bell),
            ),
          ),
        ),
      ],
    );
  }
}

/// ===========================================================================
/// SEARCH
/// ===========================================================================

class _ClinicalSearchCard extends StatelessWidget {
  const _ClinicalSearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Search clinical guidelines, medicines, tools and facilities',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.search,
                    color: colors.primary,
                    size: 20,
                  ),
                ),

                AppSpacing.md.gap,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search MediGuide',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        'Guidelines, drugs, tools and facilities',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.sm.gap,

                Icon(
                  LucideIcons.chevronRight,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// QUICK ACTIONS
/// ===========================================================================

class _HomeQuickAction {
  const _HomeQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  final Future<void> Function() onTap;
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Original compact behavior:
        // 4 across on normal phones, 2 only on very narrow screens.
        final columns = constraints.maxWidth >= 340 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,

            // Keeps approximately the same compact sizing
            // as the original HomePage.
            childAspectRatio: columns == 4 ? 0.86 : 1.45,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _QuickActionCard(
              action: actions[index],
              compact: columns == 4,
            );
          },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.compact});

  final _HomeQuickAction action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '${action.title}. ${action.subtitle}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            action.onTap();
          },
          child: Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(action.icon, color: colors.primary, size: 20),
                ),

                const SizedBox(height: 7),

                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // On wider 2-column layouts we have enough room
                // to show the description as well.
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    action.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// CONTINUE READING
/// ===========================================================================

class _ContinueReadingSection extends StatelessWidget {
  const _ContinueReadingSection({required this.items, required this.onOpen});

  final List<ReadingProgress> items;

  final ValueChanged<ReadingProgress> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _ContinueReadingCard(
              progress: items[index],
              onTap: () {
                onOpen(items[index]);
              },
            ),
          ),
      ],
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final value = progress.progressPercentage.clamp(0.0, 1.0);

    final percent = (value * 100).round();

    return Semantics(
      button: true,
      label: 'Continue reading. $percent percent complete.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    LucideIcons.bookOpenText,
                    color: colors.primary,
                    size: 22,
                  ),
                ),

                AppSpacing.md.gap,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Continue guideline',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '$percent%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock3,
                            size: 13,
                            color: colors.onSurfaceVariant,
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              progress.lastReadFormatted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                AppSpacing.sm.gap,

                Icon(
                  LucideIcons.chevronRight,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// RECENT GUIDELINES
/// ===========================================================================

class _GuidelinesPreviewList extends StatelessWidget {
  const _GuidelinesPreviewList({
    required this.guidelines,
    required this.onOpenGuideline,
  });

  final List<GuidelinePublication> guidelines;

  final void Function(GuidelinePublication guideline) onOpenGuideline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < guidelines.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == guidelines.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _GuidelinePreview(
              guideline: guidelines[index],
              onTap: () {
                onOpenGuideline(guidelines[index]);
              },
            ),
          ),
      ],
    );
  }
}

class _GuidelinePreview extends StatelessWidget {
  const _GuidelinePreview({required this.guideline, required this.onTap});

  final GuidelinePublication guideline;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final updatedAt = guideline.lastUpdated != null
        ? 'Updated ${AppDateUtils.formatDate(guideline.lastUpdated!)}'
        : 'Recently added';

    return _HomeGuidelineTile(
      title: guideline.title,
      category: guideline.programArea,
      updatedAt: updatedAt,
      onTap: onTap,
    );
  }
}

class _HomeGuidelineTile extends StatelessWidget {
  const _HomeGuidelineTile({
    required this.title,
    required this.category,
    required this.updatedAt,
    required this.onTap,
  });

  final String title;
  final String category;
  final String updatedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    LucideIcons.fileText,
                    color: colors.primary,
                    size: 21,
                  ),
                ),

                AppSpacing.md.gap,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),

                      if (category.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),

                        _GuidelineCategoryChip(label: category),
                      ],

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock3,
                            size: 13,
                            color: colors.onSurfaceVariant,
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              updatedAt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                AppSpacing.sm.gap,

                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 19,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidelineCategoryChip extends StatelessWidget {
  const _GuidelineCategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.folder,
            size: 12,
            color: colors.onSecondaryContainer,
          ),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===========================================================================
/// EMPTY RECENT STATE
/// ===========================================================================

class _NoRecentGuidelinesCard extends StatelessWidget {
  const _NoRecentGuidelinesCard({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Browse clinical guidelines',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onBrowse,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    LucideIcons.bookOpenText,
                    color: colors.primary,
                    size: 21,
                  ),
                ),

                AppSpacing.md.gap,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse guidelines',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Explore all available clinical guidance.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  LucideIcons.chevronRight,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// CHAT
/// ===========================================================================

class _ChatFloatingButton extends StatelessWidget {
  const _ChatFloatingButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final unread = unreadCount.clamp(0, 9999);

    return FloatingActionButton.small(
      onPressed: onPressed,
      tooltip: 'Conversations',
      child: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(
          LucideIcons.messageCircle,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
