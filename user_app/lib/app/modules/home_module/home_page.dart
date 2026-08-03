import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/routes/app_pages.dart';
import 'package:user_app/app/utils/date_utils.dart';

import '../../data/models/models.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/home/home_controller.dart';
import '../../translations/app_translations.dart';
import '../../utils/app_spacing.dart';
import '../../utils/loading.dart';
import '../../utils/responsive.dart';

import '../../widgets/global_search_delegate.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

import './widgets/continue_reading_card.dart';

import '../tree_selector_module/models/tree_selector_models.dart';
import '../tree_selector_module/tree_selector_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final home = ref.watch(homeControllerProvider);
    final data = home.valueOrNull ?? const HomeState();
    final userName = ref.watch(
      authControllerProvider.select(
        (value) => value.valueOrNull?.user?.name ?? 'Healthcare Professional',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              userName,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showQuickActionsMenu(context),
            tooltip: AppTranslationKey.quickActions,
            icon: const Icon(LucideIcons.layoutGrid),
          ),
          IconButton(
            onPressed: () =>
                showSearch(context: context, delegate: GlobalSearchDelegate()),
            tooltip: 'Search',
            icon: const Icon(LucideIcons.search),
          ),
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.notifications),
            tooltip: AppTranslationKey.notifications,
            icon: const Icon(LucideIcons.bell),
          ),
        ],
      ),

      floatingActionButton: Builder(
        builder: (context) {
          final unread = data.unreadMessagesCount.clamp(0, 9999);

          return FloatingActionButton.small(
            onPressed: () => Get.toNamed(AppRoutes.chatList),
            backgroundColor: cs.primary,
            child: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: Icon(LucideIcons.messageCircle, color: cs.onPrimary),
            ),
          );
        },
      ),

      body: Builder(
        builder: (context) {
          final loading = home.isLoading;

          if (loading && !data.hasContent) {
            return const Center(child: Loading.large());
          }

          return RefreshIndicator(
            onRefresh: ref.read(homeControllerProvider.notifier).refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveHorizontalPadding,
                vertical: AppSpacing.md,
              ),
              children: [
                // =====================================================
                // GUIDELINES
                // =====================================================
                SectionHeader(
                  title: AppTranslationKey.guidelines,
                  subtitle: 'Recently added and updated clinical guidance',
                  icon: LucideIcons.bookOpenText,
                  onSeeAll: _openAllGuidelines,
                ),

                AppSpacing.md.gap,

                if (data.recentlyUpdatedGuidelines.isNotEmpty) ...[
                  _GuidelinesPreviewList(
                    guidelines: data.recentlyUpdatedGuidelines,
                    onOpenGuideline: _openGuideline,
                  ),
                  AppSpacing.lg.gap,
                ] else ...[
                  _NoRecentGuidelinesCard(onBrowse: _openAllGuidelines),
                  AppSpacing.lg.gap,
                ],

                // =====================================================
                // PINNED GUIDELINES
                // =====================================================
                // if (controller.pinnedGuidelines.isNotEmpty) ...[
                //   SectionHeader(
                //     title: 'Pinned Guidelines',
                //     subtitle: 'Frequently used references',
                //     icon: LucideIcons.pin,
                //   ),

                //   AppSpacing.md.gap,

                //   SizedBox(
                //     height: 140,
                //     child: ListView.separated(
                //       scrollDirection: Axis.horizontal,
                //       itemCount: controller.pinnedGuidelines.length,
                //       separatorBuilder: (_, _) => AppSpacing.sm.gap,
                //       itemBuilder: (context, index) {
                //         final guideline = controller.pinnedGuidelines[index];

                //         return _PinnedGuidelineCard(
                //           title: guideline.displayName,
                //           category: guideline.categories.firstOrNull?.name ?? '',
                //           onTap: () => controller.openGuideline(guideline),
                //         );
                //       },
                //     ),
                //   ),

                //   AppSpacing.lg.gap,
                // ],

                // =====================================================
                // CONTINUE READING
                // =====================================================
                if (data.continueReadingItems.isNotEmpty) ...[
                  SectionHeader(
                    title: AppTranslationKey.continueReading,
                    subtitle: AppTranslationKey.resumeWhereYouLeftOff,
                    icon: LucideIcons.bookOpen,
                  ),

                  AppSpacing.md.gap,

                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.continueReadingItems.length,
                      separatorBuilder: (_, _) => AppSpacing.md.gap,
                      itemBuilder: (context, index) {
                        final progress = data.continueReadingItems[index];

                        return ContinueReadingCard(
                          progress: progress,
                          onTap: () => _continueReading(ref, progress),
                        );
                      },
                    ),
                  ),

                  AppSpacing.lg.gap,
                ],

                // =====================================================
                // FEATURED TOOLS
                // =====================================================
                // if (controller.featuredCalculators.isNotEmpty && !loading) ...[
                //   SectionHeader(
                //     title: AppTranslationKey.featuredTools,
                //     subtitle: AppTranslationKey.essentialCalculatorsAndTools,
                //     icon: LucideIcons.calculator,
                //     onSeeAll: () => Get.toNamed(AppRoutes.tools),
                //   ),

                //   AppSpacing.md.gap,

                //   SizedBox(
                //     height: 140,
                //     child: ListView.separated(
                //       scrollDirection: Axis.horizontal,
                //       itemCount: controller.featuredCalculators.length,
                //       separatorBuilder: (_, _) => AppSpacing.sm.gap,
                //       itemBuilder: (context, index) {
                //         final calculator = controller.featuredCalculators[index];

                //         return FeaturedCalculatorChip(
                //           calculator: calculator,
                //           onTap: () => Get.toNamed(
                //             AppRoutes.useCalculator,
                //             arguments: calculator,
                //           ),
                //         );
                //       },
                //     ),
                //   ),
                // ],
                AppSpacing.xxxl.gap,
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAllGuidelines() {
    Get.toNamed(
      AppRoutes.guidelines,
      arguments: {'filterType': 'all', 'title': 'All Guidelines'},
    );
  }

  void _openGuideline(Guideline guideline) {
    Get.toNamed(AppRoutes.readGuideline, arguments: guideline);
  }

  Future<void> _continueReading(WidgetRef ref, ReadingProgress progress) async {
    try {
      final guideline = await ref
          .read(homeControllerProvider.notifier)
          .guideline(progress.guidelineId);
      _openGuideline(guideline);
    } catch (_) {
      // The existing card remains visible and can be retried while offline.
    }
  }

  Future<void> _showQuickActionsMenu(BuildContext context) async {
    final actions = [
      _HomeQuickAction(
        icon: LucideIcons.pill,
        title: AppTranslationKey.drugIndex,
        subtitle: 'Drug references',
        color: Colors.blue,
        onTap: () async {
          Get.toNamed(AppRoutes.drugIndex);
        },
      ),
      _HomeQuickAction(
        icon: LucideIcons.calculator,
        title: 'Clinical Tools',
        subtitle: 'Decision support',
        color: Colors.purple,
        onTap: () async {
          Get.toNamed(AppRoutes.tools);
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

          if (result != null) {
            Get.toNamed(
              AppRoutes.consultants,
              arguments: {'treeFilters': result.filters},
            );
          }
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

          if (result != null) {
            Get.toNamed(
              AppRoutes.healthInfrastructure,
              arguments: {'treeFilters': result.filters},
            );
          }
        },
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _QuickActionsSheet(actions: actions),
    );
  }
}

class _HomeQuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Future<void> Function() onTap;

  const _HomeQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionsSheet extends StatelessWidget {
  final List<_HomeQuickAction> actions;

  const _QuickActionsSheet({required this.actions});

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
              ...actions.map((action) => _QuickActionMenuTile(action: action)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionMenuTile extends StatelessWidget {
  final _HomeQuickAction action;

  const _QuickActionMenuTile({required this.action});

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

class _GuidelinesPreviewList extends StatelessWidget {
  final List<Guideline> guidelines;
  final void Function(Guideline guideline) onOpenGuideline;

  const _GuidelinesPreviewList({
    required this.guidelines,
    required this.onOpenGuideline,
  });

  @override
  Widget build(BuildContext context) {
    final visibleGuidelines = guidelines.take(4).toList();

    return Column(
      children: visibleGuidelines.map((guideline) {
        final category = guideline.categories.firstOrNull?.name ?? '';
        final updatedAt = guideline.updatedDate != null
            ? 'Updated on ${AppDateUtils.formatDate(guideline.updatedDate!)}'
            : 'Recently added';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _HomeGuidelineTile(
            title: guideline.displayName,
            category: category,
            priority: guideline.priority,
            updatedAt: updatedAt,
            onTap: () => onOpenGuideline(guideline),
          ),
        );
      }).toList(),
    );
  }
}

class _HomeGuidelineTile extends StatelessWidget {
  final String title;
  final String category;
  final String priority;
  final String updatedAt;
  final VoidCallback onTap;

  const _HomeGuidelineTile({
    required this.title,
    required this.category,
    required this.priority,
    required this.updatedAt,
    required this.onTap,
  });

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

    return lower[0].toUpperCase() + lower.substring(1);
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
  final String label;
  final IconData icon;
  final Color? color;

  const _MiniMetaChip({required this.label, required this.icon, this.color});

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

class _NoRecentGuidelinesCard extends StatelessWidget {
  final VoidCallback onBrowse;

  const _NoRecentGuidelinesCard({required this.onBrowse});

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

// Retained for the pinned-guidelines section that is currently feature-gated.
// ignore: unused_element
class _PinnedGuidelineCard extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback onTap;

  const _PinnedGuidelineCard({
    required this.title,
    required this.category,
    required this.onTap,
  });

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
