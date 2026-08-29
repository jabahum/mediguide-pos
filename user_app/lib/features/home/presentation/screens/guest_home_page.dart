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
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';
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
      final enabled = ref.watch(outbreakFeatureEnabledProvider);
      if (!enabled) return const <PublicOutbreak>[];
      final page = await ref
          .watch(outbreakRepositoryProvider)
          .outbreaks(query: const OutbreakQuery(status: 'active'));
      final primary = selectPrimaryOutbreak(page.items);
      return primary == null ? const <PublicOutbreak>[] : [primary];
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            // OFFLINE
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

// =============================================================================
// SEARCH
// =============================================================================

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

// =============================================================================
// ACTIVE OUTBREAK
// =============================================================================

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

// =============================================================================
// PUBLICATIONS
// =============================================================================

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
        .take(8)
        .toList(growable: false);

    final latest = publications.take(4).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===================================================================
        // CLINICAL CATEGORIES
        // ===================================================================
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

          _CategoryQuickAccessGrid(
            categories: areas,
            onCategory: (area) {
              context.push(AppRoutes.publicGuidelinesForProgramArea(area));
            },
          ),

          AppSpacing.gapXl,
        ],

        // ===================================================================
        // LATEST GUIDANCE
        // ===================================================================
        SectionHeader(
          title: 'Latest guidance',
          subtitle: 'Recently published or updated',
          icon: LucideIcons.bookOpenText,
          onSeeAll: () {
            context.push(AppRoutes.publicGuidelines);
          },
        ),

        AppSpacing.gapSm,

        for (var index = 0; index < latest.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == latest.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _PublicationCard(publication: latest[index]),
          ),
      ],
    );
  }
}

// =============================================================================
// CATEGORY QUICK ACCESS
// =============================================================================

class _CategoryQuickAccessGrid extends StatelessWidget {
  const _CategoryQuickAccessGrid({
    required this.categories,
    required this.onCategory,
  });

  final List<String> categories;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        //
        // This intentionally mirrors the Quick Access layout:
        //
        // normal phone  -> 4 columns
        // narrow phone  -> 2 columns
        // larger device -> still compact, up to 4
        //
        final columns = constraints.maxWidth >= 340 ? 4 : 2;

        final textScale = MediaQuery.textScalerOf(context).scale(1);

        final largeText = textScale >= 1.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
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
          itemBuilder: (context, index) {
            final category = categories[index];

            return _CategoryQuickAccessTile(
              label: category,
              onTap: () {
                onCategory(category);
              },
            );
          },
        );
      },
    );
  }
}

class _CategoryQuickAccessTile extends StatelessWidget {
  const _CategoryQuickAccessTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final icon = _categoryIcon(label);

    return Semantics(
      button: true,
      label: 'Browse $label guidelines',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('guest-category-$label'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: colors.onSecondaryContainer,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    // Maternal / reproductive health
    if (value.contains('maternal') ||
        value.contains('pregnan') ||
        value.contains('reproductive') ||
        value.contains('obstetric')) {
      return LucideIcons.heartHandshake;
    }

    // Child health
    if (value.contains('child') ||
        value.contains('paediatric') ||
        value.contains('pediatric') ||
        value.contains('newborn') ||
        value.contains('neonatal')) {
      return LucideIcons.baby;
    }

    // Diabetes / endocrine
    if (value.contains('diabetes') || value.contains('endocr')) {
      return LucideIcons.droplets;
    }

    // HIV / AIDS
    if (value.contains('hiv') || value.contains('aids')) {
      return LucideIcons.ribbon;
    }

    // TB / respiratory
    if (value.contains('tb') ||
        value.contains('tuberculosis') ||
        value.contains('respiratory') ||
        value.contains('pulmonary')) {
      return LucideIcons.activity;
    }

    // Cardiovascular
    if (value.contains('cardio') ||
        value.contains('heart') ||
        value.contains('hypertension')) {
      return LucideIcons.heartPulse;
    }

    // Mental health
    if (value.contains('mental') || value.contains('psychiatr')) {
      return LucideIcons.brain;
    }

    // Emergency / critical care
    if (value.contains('emergency') ||
        value.contains('critical') ||
        value.contains('acute')) {
      return LucideIcons.siren;
    }

    // Infectious / communicable diseases
    if (value.contains('infect') ||
        value.contains('communicable') ||
        value.contains('disease')) {
      return LucideIcons.bug;
    }

    // Nutrition
    if (value.contains('nutrition') || value.contains('malnutrition')) {
      return LucideIcons.apple;
    }

    // Surgery
    if (value.contains('surgery') || value.contains('surgical')) {
      return LucideIcons.cross;
    }

    // Medicines / pharmacy
    if (value.contains('medicine') ||
        value.contains('drug') ||
        value.contains('pharmacy') ||
        value.contains('pharmaceutical')) {
      return LucideIcons.pill;
    }

    // Laboratory
    if (value.contains('laboratory') ||
        value.contains('lab') ||
        value.contains('diagnostic')) {
      return LucideIcons.flaskConical;
    }

    // Eye / ophthalmology
    if (value.contains('eye') || value.contains('ophthalm')) {
      return LucideIcons.eye;
    }

    // Dental / oral
    if (value.contains('dental') || value.contains('oral')) {
      return LucideIcons.smile;
    }

    // Cancer / oncology
    if (value.contains('cancer') ||
        value.contains('oncology') ||
        value.contains('oncological')) {
      return LucideIcons.ribbon;
    }

    // General / default clinical guidance
    return LucideIcons.bookOpenText;
  }
}
// =============================================================================
// PUBLICATION CARD
// =============================================================================

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

// =============================================================================
// QUICK ACTIONS
// =============================================================================

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
            return _QuickActionCard(action: actions[index]);
          },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

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
            padding: const EdgeInsets.all(AppSpacing.xs),
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

// =============================================================================
// OFFLINE ACCESS
// =============================================================================

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

// =============================================================================
// EMPTY PUBLICATIONS
// =============================================================================

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

// =============================================================================
// LOADING
// =============================================================================

class _PublicationSkeleton extends StatelessWidget {
  const _PublicationSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                        color: colors.surfaceContainerHigh,
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

// =============================================================================
// ERROR
// =============================================================================

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
