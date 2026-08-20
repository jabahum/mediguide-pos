import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';
import 'package:user_app/shared/widgets/section_header.dart';

final guestHomePublicationsProvider =
    FutureProvider.autoDispose<List<GuidelinePublication>>((ref) async {
      final page = await ref
          .watch(guidelinePublicationRepositoryProvider)
          .publications(page: 1, perPage: 12);

      return page.items;
    });

final guestHomeOutbreaksProvider =
    FutureProvider.autoDispose<List<PublicOutbreak>>((ref) async {
      return ref.watch(outbreakRepositoryProvider).outbreaks(status: 'active');
    });

class GuestHomePage extends ConsumerWidget {
  const GuestHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publications = ref.watch(guestHomePublicationsProvider);

    final outbreaks = ref.watch(guestHomeOutbreaksProvider);

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MediGuide',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Clinical guidance when you need it',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.push(AppRoutes.login);
            },
            icon: const Icon(LucideIcons.logIn, size: 18),
            label: const Text('Sign in'),
          ),
          AppSpacing.hGapSm,
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(guestHomePublicationsProvider);

          ref.invalidate(guestHomeOutbreaksProvider);

          await Future.wait([
            ref.read(guestHomePublicationsProvider.future),
            ref.read(guestHomeOutbreaksProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            AppSpacing.md,
            Responsive.horizontalPadding(context),
            AppSpacing.xxxl,
          ),
          children: [
            // =================================================================
            // SEARCH
            // =================================================================
            _GuestSearchCard(
              onTap: () {
                context.push(AppRoutes.search);
              },
            ),

            AppSpacing.gapLg,

            // =================================================================
            // ACTIVE OUTBREAK
            // =================================================================
            outbreaks.when(
              loading: () => const LinearProgressIndicator(minHeight: 3),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _ActiveOutbreakCard(
                  outbreak: items.first,
                  activeCount: items.length,
                );
              },
            ),

            if (outbreaks.valueOrNull?.isNotEmpty == true) AppSpacing.gapXl,

            // =================================================================
            // QUICK ACCESS
            // =================================================================
            const SectionHeader(title: 'Quick access'),

            AppSpacing.gapSm,

            _QuickActionGrid(
              actions: [
                _QuickAction(
                  label: 'Drug Index',
                  icon: LucideIcons.pill,
                  route: AppRoutes.drugIndex,
                ),
                _QuickAction(
                  label: 'Calculators',
                  icon: LucideIcons.calculator,
                  route: AppRoutes.tools,
                ),
                _QuickAction(
                  label: 'Algorithms',
                  icon: LucideIcons.gitBranch,
                  route: AppRoutes.publicGuidelines,
                ),
                _QuickAction(
                  label: 'Procedures',
                  icon: LucideIcons.clipboardList,
                  route: AppRoutes.publicGuidelines,
                ),
              ],
            ),

            AppSpacing.gapXl,

            // =================================================================
            // PUBLICATIONS
            // =================================================================
            publications.when(
              loading: () => const _PublicationSkeleton(),
              error: (_, _) => _SectionError(
                onRetry: () {
                  ref.invalidate(guestHomePublicationsProvider);
                },
              ),
              data: (items) {
                return _PublicationSections(publications: items);
              },
            ),

            AppSpacing.gapXl,

            // =================================================================
            // OFFLINE INFORMATION
            // =================================================================
            _OfflineAccessCard(
              onTap: () {
                context.push(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SEARCH
// ===========================================================================

class _GuestSearchCard extends StatelessWidget {
  const _GuestSearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Search MediGuide clinical content',
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

                AppSpacing.hGapMd,

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
                        'Conditions, drugs, procedures and tools',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.hGapSm,

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

// ===========================================================================
// ACTIVE OUTBREAK
// ===========================================================================

class _ActiveOutbreakCard extends StatelessWidget {
  const _ActiveOutbreakCard({
    required this.outbreak,
    required this.activeCount,
  });

  final PublicOutbreak outbreak;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Active outbreak. ${outbreak.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(AppRoutes.outbreak(outbreak.id));
          },
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.error.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        LucideIcons.siren,
                        color: colors.error,
                        size: 20,
                      ),
                    ),

                    AppSpacing.hGapSm,

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE OUTBREAK',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.error,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                          ),
                          if (activeCount > 1)
                            Text(
                              '$activeCount active outbreak alerts',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onErrorContainer),
                            ),
                        ],
                      ),
                    ),

                    const Icon(LucideIcons.chevronRight),
                  ],
                ),

                AppSpacing.gapMd,

                Text(
                  outbreak.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (outbreak.geographicArea.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 14),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          outbreak.geographicArea,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],

                if (outbreak.summary.trim().isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Text(
                    outbreak.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],

                AppSpacing.gapMd,

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Open response hub',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.arrowUpRight,
                      size: 18,
                      color: colors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PUBLICATIONS
// ===========================================================================

class _PublicationSections extends StatelessWidget {
  const _PublicationSections({required this.publications});

  final List<GuidelinePublication> publications;

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return _EmptyPublicationsCard(
        onTap: () {
          context.push(AppRoutes.publicGuidelines);
        },
      );
    }

    final areas = publications
        .map((item) => item.programArea.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(6)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------------------------------------------------------------------
        // CATEGORIES
        // -------------------------------------------------------------------
        if (areas.isNotEmpty) ...[
          SectionHeader(
            title: 'Clinical categories',
            subtitle: 'Browse guidance by programme area',
            icon: LucideIcons.layoutGrid,
            onSeeAll: () {
              context.push(AppRoutes.publicGuidelines);
            },
          ),

          AppSpacing.gapSm,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final area in areas)
                _CategoryChip(
                  label: area,
                  onTap: () {
                    //
                    // This currently opens the full guideline
                    // catalogue because no category-specific route
                    // was provided in the shared code.
                    //
                    context.push(AppRoutes.publicGuidelines);
                  },
                ),
            ],
          ),

          AppSpacing.gapXl,
        ],

        // -------------------------------------------------------------------
        // LATEST
        // -------------------------------------------------------------------
        SectionHeader(
          title: 'Latest guidance',
          subtitle: 'Recently published or updated',
          icon: LucideIcons.bookOpenText,
          onSeeAll: () {
            context.push(AppRoutes.publicGuidelines);
          },
        ),

        AppSpacing.gapSm,

        for (var index = 0; index < publications.take(4).length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index < publications.take(4).length - 1
                  ? AppSpacing.sm
                  : 0,
            ),
            child: _PublicationCard(publication: publications[index]),
          ),
      ],
    );
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({required this.publication});

  final GuidelinePublication publication;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final metadata = <String>[
      if (publication.sourceOrganization.trim().isNotEmpty)
        publication.sourceOrganization.trim(),
      if (publication.version.trim().isNotEmpty)
        'v${publication.version.trim()}',
    ];

    return Semantics(
      button: true,
      label: publication.title,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push(AppRoutes.publicGuideline(publication.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ClinicalIconTile(icon: LucideIcons.fileText),

                AppSpacing.hGapMd,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),

                      if (publication.programArea.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _ProgramAreaBadge(label: publication.programArea),
                      ],

                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metadata.join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),

                AppSpacing.hGapSm,

                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
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

class _ProgramAreaBadge extends StatelessWidget {
  const _ProgramAreaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ===========================================================================
// CATEGORY CHIP
// ===========================================================================

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(LucideIcons.bookOpen, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

// ===========================================================================
// QUICK ACTIONS
// ===========================================================================

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        //
        // Keep the same compact sizing as the
        // logged-in home screen.
        //
        final columns = constraints.maxWidth >= 340 ? 4 : 2;

        final textScale = MediaQuery.textScalerOf(context).scale(1);

        final largeText = textScale >= 1.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: largeText
                ? 0.72
                : columns == 4
                ? 0.86
                : 1.45,
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

  final _QuickAction action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: action.label,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push(action.route);
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
                  child: Icon(action.icon, size: 19, color: colors.primary),
                ),

                const SizedBox(height: 7),

                Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

// ===========================================================================
// OFFLINE ACCESS
// ===========================================================================

class _OfflineAccessCard extends StatelessWidget {
  const _OfflineAccessCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Offline access information',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.cloudDownload,
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
                        'Offline access',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sign in to save guidelines for reliable offline access.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.hGapSm,

                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
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

// ===========================================================================
// EMPTY PUBLICATIONS
// ===========================================================================

class _EmptyPublicationsCard extends StatelessWidget {
  const _EmptyPublicationsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const ClinicalIconTile(icon: LucideIcons.bookOpenText),

              AppSpacing.hGapMd,

              const Expanded(
                child: Text('No published guidelines are currently available.'),
              ),

              const Icon(LucideIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// LOADING
// ===========================================================================

class _PublicationSkeleton extends StatelessWidget {
  const _PublicationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 3; index++)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SizedBox(
              height: 84,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    AppSpacing.hGapMd,

                    const Expanded(
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// ERROR
// ===========================================================================

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const ClinicalIconTile(icon: LucideIcons.cloudOff),

            AppSpacing.hGapMd,

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest guidance is unavailable',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text('Other sections remain available.'),
                ],
              ),
            ),

            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
