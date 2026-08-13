import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/date_utils.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_state.dart';
import 'package:user_app/features/home/presentation/widgets/continue_reading_card.dart';

import 'package:user_app/features/tree_selector/data/models/tree_selector_models.dart';
import 'package:user_app/features/tree_selector/presentation/screens/tree_selector_page.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/glass_card.dart';
import 'package:user_app/shared/widgets/section_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.greetingHour})
    : assert(greetingHour == null || (greetingHour >= 0 && greetingHour <= 23));

  /// Overrides the local clock only for deterministic previews and tests.
  final int? greetingHour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;

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

    return Scaffold(
      backgroundColor: cs.surface,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        toolbarHeight: professionalContext.isEmpty ? kToolbarHeight : 82,
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (professionalContext.isNotEmpty)
              Text(
                professionalContext,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showQuickActionsMenu(context);
            },
            tooltip: AppTranslationKey.quickActions,
            icon: const Icon(LucideIcons.layoutGrid),
          ),
          IconButton(
            onPressed: () => AppNavigator.push(AppRoutes.search),
            tooltip: 'Search',
            icon: const Icon(LucideIcons.search),
          ),
          IconButton(
            onPressed: () {
              AppNavigator.push(AppRoutes.notifications);
            },
            tooltip: AppTranslationKey.notifications,
            icon: const Icon(LucideIcons.bell),
          ),
        ],
      ),

      // =====================================================
      // CHAT FAB
      // =====================================================
      floatingActionButton: _ChatFloatingButton(
        unreadCount: data.unreadMessagesCount,
        onPressed: () {
          AppNavigator.push(AppRoutes.chatList);
        },
      ),

      // =====================================================
      // BODY
      // =====================================================
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
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<HomeState> home,
    required HomeState data,
    required HomeController controller,
  }) {
    final cs = Theme.of(context).colorScheme;
    // =====================================================
    // INITIAL LOADING
    //
    // Only block the whole page if we have no usable
    // cached/previous content.
    // =====================================================

    if (home.isLoading && !data.hasContent) {
      return const AppLoadingView(message: 'Loading MediGuide...');
    }

    // =====================================================
    // INITIAL ERROR
    //
    // If we already have old/cached content, keep showing it
    // rather than replacing the whole home screen.
    // =====================================================

    if (home.hasError && !data.hasContent) {
      return AppErrorView(
        error: home.error ?? 'Unable to load home content',
        onRetry: controller.refresh,
      );
    }

    // =====================================================
    // CONTENT
    // =====================================================

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: AppSpacing.md,
        ),
        children: [
          // =================================================
          // REFRESH / STALE CONTENT INDICATOR
          // =================================================
          if (home.isLoading && data.hasContent) ...[
            const LinearProgressIndicator(),
            AppSpacing.md.gap,
          ],

          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              minTileHeight: 56,
              leading: const Icon(LucideIcons.search),
              title: const Text('Search guidelines, drugs, tools and more'),
              trailing: const Icon(LucideIcons.slidersHorizontal),
              onTap: () => AppNavigator.push(AppRoutes.search),
            ),
          ),
          AppSpacing.lg.gap,

          // =================================================
          // CONTINUE READING
          // =================================================
          if (data.continueReadingItems.isNotEmpty) ...[
            SectionHeader(
              title: AppTranslationKey.continueReading,
              onSeeAll: () => AppNavigator.push(AppRoutes.library),
            ),

            AppSpacing.sm.gap,

            ContinueReadingCard(
              compact: true,
              progress: data.continueReadingItems.first,
              onTap: () =>
                  _continueReading(ref, data.continueReadingItems.first),
            ),

            AppSpacing.lg.gap,
          ],

          // =================================================
          // RECENT UPDATES
          // =================================================
          SectionHeader(title: 'Recent updates', onSeeAll: _openAllGuidelines),

          AppSpacing.sm.gap,

          if (data.recentlyUpdatedGuidelines.isNotEmpty) ...[
            _GuidelinesPreviewList(
              guidelines: data.recentlyUpdatedGuidelines.take(3).toList(),
              onOpenGuideline: (guideline) => _openGuideline(ref, guideline),
            ),
          ] else ...[
            _NoRecentGuidelinesCard(onBrowse: _openAllGuidelines),
          ],

          AppSpacing.lg.gap,

          SectionHeader(title: 'Quick actions'),
          AppSpacing.sm.gap,
          _QuickActionGrid(
            actions: [
              _HomeQuickAction(
                icon: LucideIcons.pill,
                title: 'Drug Index',
                subtitle: 'Reviewed medicines',
                color: cs.primary,
                onTap: () async {
                  await AppNavigator.push(AppRoutes.drugIndex);
                },
              ),
              _HomeQuickAction(
                icon: LucideIcons.calculator,
                title: 'Calculators',
                subtitle: 'Clinical tools',
                color: cs.secondary,
                onTap: () async {
                  await AppNavigator.push(AppRoutes.calculators);
                },
              ),
              _HomeQuickAction(
                icon: LucideIcons.bookOpenText,
                title: 'Guidelines',
                subtitle: 'Published guidance',
                color: cs.tertiary,
                onTap: () async {
                  await AppNavigator.push(AppRoutes.publicGuidelines);
                },
              ),
              _HomeQuickAction(
                icon: LucideIcons.hospital,
                title: 'Facilities',
                subtitle: 'Find health services',
                color: cs.primary,
                onTap: () async {
                  await AppNavigator.push(AppRoutes.healthFacilities);
                },
              ),
            ],
          ),
          AppSpacing.lg.gap,

          // =================================================
          // OPTIONAL FEATURED TOOLS
          // =================================================
          //
          // Your controller already loads featured calculators.
          // This can be re-enabled when you want it visible.
          //
          // if (data.featuredCalculators.isNotEmpty) ...[
          //   SectionHeader(
          //     title: AppTranslationKey.featuredTools,
          //     subtitle:
          //         AppTranslationKey.essentialCalculatorsAndTools,
          //     icon: LucideIcons.calculator,
          //     onSeeAll: () {
          //       AppNavigator.push(AppRoutes.tools);
          //     },
          //   ),
          //
          //   AppSpacing.md.gap,
          //
          //   SizedBox(
          //     height: 140,
          //     child: ListView.separated(
          //       scrollDirection: Axis.horizontal,
          //       itemCount: data.featuredCalculators.length,
          //       separatorBuilder:
          //           (_, _) => AppSpacing.sm.gap,
          //       itemBuilder: (context, index) {
          //         final calculator =
          //             data.featuredCalculators[index];
          //
          //         return FeaturedCalculatorChip(
          //           calculator: calculator,
          //           onTap: () {
          //             AppNavigator.push(
          //               AppRoutes.calculator(
          //                 calculator.id,
          //               ),
          //               extra: calculator,
          //             );
          //           },
          //         );
          //       },
          //     ),
          //   ),
          //
          //   AppSpacing.lg.gap,
          // ],

          // =================================================
          // COMPLETELY EMPTY HOME
          // =================================================
          if (!data.hasContent && data.recentlyUpdatedGuidelines.isEmpty)
            EmptyState.noData(
              title: 'No content available',
              description:
                  'Clinical guidelines and tools will appear here when available.',
              actionLabel: 'Refresh',
              onAction: () {
                controller.refresh();
              },
            ),

          AppSpacing.xxxl.gap,
        ],
      ),
    );
  }

  // =======================================================
  // NAVIGATION
  // =======================================================

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
    if (guidelineId.isEmpty) return;

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
      // The existing progress card remains available.
      // Offline/network errors should not remove it.
    }
  }

  // =======================================================
  // QUICK ACTIONS
  // =======================================================

  static Future<void> _showQuickActionsMenu(BuildContext context) async {
    final actions = <_HomeQuickAction>[
      _HomeQuickAction(
        icon: LucideIcons.pill,
        title: AppTranslationKey.drugIndex,
        subtitle: 'Drug references',
        color: Colors.blue,
        onTap: () async {
          await AppNavigator.push(AppRoutes.drugIndex);
        },
      ),
      _HomeQuickAction(
        icon: LucideIcons.calculator,
        title: 'Clinical Tools',
        subtitle: 'Decision support',
        color: Colors.purple,
        onTap: () async {
          await AppNavigator.push(AppRoutes.tools);
        },
      ),
      _HomeQuickAction(
        icon: LucideIcons.messageCircle,
        title: AppTranslationKey.chatWithConsultant,
        subtitle: 'Talk to experts',
        color: Colors.teal,
        onTap: () async {
          final result = await TreeSelectorPage.show(
            config: TreeSelectorConfig(
              title: AppTranslationKey.chatWithConsultant,
              endpointPath: '/api/consultants/tree',
            ),
          );

          if (result == null) {
            return;
          }

          await AppNavigator.push(
            AppRoutes.consultants,
            extra: {'treeFilters': result.filters},
          );
        },
      ),
      _HomeQuickAction(
        icon: LucideIcons.mapPin,
        title: AppTranslationKey.healthInfrastructure,
        subtitle: 'Find facilities',
        color: Colors.orange,
        onTap: () async {
          final result = await TreeSelectorPage.show(
            config: TreeSelectorConfig(
              title: AppTranslationKey.healthInfrastructure,
              endpointPath: '/api/health-facilities/tree',
            ),
          );

          if (result == null) {
            return;
          }

          await AppNavigator.push(
            AppRoutes.healthInfrastructure,
            extra: {'treeFilters': result.filters},
          );
        },
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) {
        return _QuickActionsSheet(actions: actions);
      },
    );
  }
}

// =========================================================
// CHAT FLOATING BUTTON
// =========================================================

class _ChatFloatingButton extends StatelessWidget {
  const _ChatFloatingButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final unread = unreadCount.clamp(0, 9999);

    return FloatingActionButton.small(
      onPressed: onPressed,
      backgroundColor: cs.primary,
      tooltip: 'Conversations',
      child: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(LucideIcons.messageCircle, color: cs.onPrimary),
      ),
    );
  }
}

// =========================================================
// QUICK ACTION MODEL
// =========================================================

class _HomeQuickAction {
  const _HomeQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Future<void> Function() onTap;
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 340 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: columns == 4 ? 0.86 : 1.45,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Semantics(
            button: true,
            label: '${action.title}. ${action.subtitle}',
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: action.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(action.icon, color: action.color, size: 20),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        action.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// =========================================================
// QUICK ACTION SHEET
// =========================================================

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({required this.actions});

  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.responsiveHorizontalPadding,
            0,
            context.responsiveHorizontalPadding,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslationKey.quickActions,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              AppSpacing.sm.gap,

              for (final action in actions)
                _QuickActionMenuTile(action: action),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionMenuTile extends StatelessWidget {
  const _QuickActionMenuTile({required this.action});

  final _HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(action.icon, color: action.color, size: 20),
        ),
        title: Text(
          action.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          action.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
        onTap: () async {
          Navigator.of(context).pop();

          await action.onTap();
        },
      ),
    );
  }
}

// =========================================================
// GUIDELINE PREVIEW
// =========================================================

class _GuidelinesPreviewList extends StatelessWidget {
  const _GuidelinesPreviewList({
    required this.guidelines,
    required this.onOpenGuideline,
  });

  final List<GuidelinePublication> guidelines;
  final void Function(GuidelinePublication guideline) onOpenGuideline;

  @override
  Widget build(BuildContext context) {
    final visibleGuidelines = guidelines.take(4).toList(growable: false);

    return Column(
      children: [
        for (var index = 0; index < visibleGuidelines.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == visibleGuidelines.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _GuidelinePreview(
              guideline: visibleGuidelines[index],
              onTap: () {
                onOpenGuideline(visibleGuidelines[index]);
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
    final category = guideline.programArea;

    final updatedAt = guideline.lastUpdated != null
        ? 'Updated on ${AppDateUtils.formatDate(guideline.lastUpdated!)}'
        : 'Recently added';

    return _HomeGuidelineTile(
      title: guideline.title,
      category: category,
      priority: '',
      updatedAt: updatedAt,
      onTap: onTap,
    );
  }
}

class _HomeGuidelineTile extends StatelessWidget {
  const _HomeGuidelineTile({
    required this.title,
    required this.category,
    required this.priority,
    required this.updatedAt,
    required this.onTap,
  });

  final String title;
  final String category;
  final String priority;
  final String updatedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final priorityColor = _priorityColor(priority);

    final priorityLabel = _formatPriority(priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.fileText, color: cs.primary, size: 22),
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
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (category.isNotEmpty)
                          _MiniMetaChip(
                            label: category,
                            icon: LucideIcons.folder,
                          ),

                        if (priorityLabel.isNotEmpty)
                          _MiniMetaChip(
                            label: priorityLabel,
                            icon: LucideIcons.triangleAlert,
                            color: priorityColor,
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      updatedAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.sm.gap,

              Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPriority(String priority) {
    final value = priority.trim();

    if (value.isEmpty) {
      return '';
    }

    final lower = value.toLowerCase();

    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Color _priorityColor(String priority) {
    final value = priority.toLowerCase();

    if (value.contains('critical') || value.contains('high')) {
      return const Color(0xFFDC2626);
    }

    if (value.contains('medium')) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF64748B);
  }
}

class _MiniMetaChip extends StatelessWidget {
  const _MiniMetaChip({required this.label, required this.icon, this.color});

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final effectiveColor = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// NO RECENT GUIDELINES
// =========================================================

class _NoRecentGuidelinesCard extends StatelessWidget {
  const _NoRecentGuidelinesCard({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onBrowse,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.bookOpenText,
                  color: cs.primary,
                  size: 22,
                ),
              ),

              AppSpacing.md.gap,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse Guidelines',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Open all available clinical guidance.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// PINNED GUIDELINE
//
// Kept because your controller already exposes pinned
// guidelines even though the section is currently hidden.
// =========================================================

// ignore: unused_element
class _PinnedGuidelineCard extends StatelessWidget {
  const _PinnedGuidelineCard({
    required this.title,
    required this.category,
    required this.onTap,
  });

  final String title;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return SizedBox(
      width: 220,
      child: GlassCard.compact(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.pin),

                const Spacer(),

                Text(
                  category,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
