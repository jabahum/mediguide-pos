part of '../screens/home_page.dart';

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

class _LoggedInOutbreakBanner extends StatelessWidget {
  const _LoggedInOutbreakBanner({required this.outbreak});

  final PublicOutbreak outbreak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Active outbreak: ${outbreak.title}',
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => AppNavigator.push(AppRoutes.outbreak(outbreak.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.siren, color: colors.onErrorContainer),
                AppSpacing.md.gap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE OUTBREAK',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outbreak.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (outbreak.geographicArea.isNotEmpty)
                        Text(
                          outbreak.geographicArea,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onErrorContainer),
                        ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: colors.onErrorContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
