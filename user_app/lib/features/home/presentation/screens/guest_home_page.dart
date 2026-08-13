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
import 'package:user_app/shared/widgets/section_header.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

final guestHomePublicationsProvider =
    FutureProvider.autoDispose<List<GuidelinePublication>>((ref) async {
      final page = await ref
          .watch(guidelinePublicationRepositoryProvider)
          .publications(page: 1, perPage: 12);
      return page.items;
    });

final guestHomeOutbreaksProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(outbreakRepositoryProvider).outbreaks(status: 'active'),
);

class GuestHomePage extends ConsumerWidget {
  const GuestHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publications = ref.watch(guestHomePublicationsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MediGuide'),
        actions: [
          IconButton(
            tooltip: 'Sign in to view notifications',
            onPressed: () => context.push(AppRoutes.login),
            icon: const Icon(LucideIcons.bell),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.refresh(guestHomePublicationsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: AppSpacing.md,
          ),
          children: [
            Semantics(
              button: true,
              label: 'Search MediGuide clinical content',
              child: SearchBar(
                hintText: 'Search conditions, drugs, procedures…',
                leading: const Icon(LucideIcons.search),
                trailing: const [Icon(LucideIcons.slidersHorizontal)],
                onTap: () => context.push(AppRoutes.search),
              ),
            ),
            AppSpacing.gapLg,
            ref
                .watch(guestHomeOutbreaksProvider)
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : _ActiveOutbreakCard(outbreak: items.first),
                ),
            AppSpacing.gapLg,
            const SectionHeader(title: 'Emergency care'),
            AppSpacing.gapSm,
            _QuickActionGrid(
              actions: [
                _QuickAction(
                  'Sepsis',
                  LucideIcons.heartPulse,
                  AppRoutes.search,
                ),
                _QuickAction('Stroke', LucideIcons.brain, AppRoutes.search),
                _QuickAction('DKA', LucideIcons.droplets, AppRoutes.tools),
                _QuickAction(
                  'CPR',
                  LucideIcons.activity,
                  AppRoutes.publicGuidelines,
                ),
              ],
            ),
            AppSpacing.gapLg,
            const SectionHeader(title: 'Quick access'),
            AppSpacing.gapSm,
            _QuickActionGrid(
              actions: [
                _QuickAction(
                  'Drug index',
                  LucideIcons.pill,
                  AppRoutes.drugIndex,
                ),
                _QuickAction(
                  'Calculators',
                  LucideIcons.calculator,
                  AppRoutes.tools,
                ),
                _QuickAction(
                  'Algorithms',
                  LucideIcons.gitBranch,
                  AppRoutes.publicGuidelines,
                ),
                _QuickAction(
                  'Procedures',
                  LucideIcons.clipboardList,
                  AppRoutes.publicGuidelines,
                ),
              ],
            ),
            AppSpacing.gapLg,
            publications.when(
              loading: () => const _PublicationSkeleton(),
              error: (_, _) => _SectionError(
                onRetry: () => ref.invalidate(guestHomePublicationsProvider),
              ),
              data: (items) => _PublicationSections(publications: items),
            ),
            AppSpacing.gapLg,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.cloudDownload,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    AppSpacing.gapMd,
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline access',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Previously opened public guidance remains available when a connection is interrupted.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOutbreakCard extends StatelessWidget {
  const _ActiveOutbreakCard({required this.outbreak});
  final PublicOutbreak outbreak;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.35),
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(AppRoutes.outbreak(outbreak.id)),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.siren,
                  color: Theme.of(context).colorScheme.error,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    'ACTIVE OUTBREAK',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    outbreak.status,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              outbreak.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (outbreak.geographicArea.isNotEmpty)
              Text(outbreak.geographicArea),
            if (outbreak.summary.isNotEmpty) ...[
              AppSpacing.gapSm,
              Text(
                outbreak.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            AppSpacing.gapSm,
            const Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Open response hub'),
                  AppSpacing.gapXs,
                  Icon(LucideIcons.chevronRight, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PublicationSections extends StatelessWidget {
  const _PublicationSections({required this.publications});
  final List<GuidelinePublication> publications;

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('No published guidelines are currently available.'),
        ),
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
        if (areas.isNotEmpty) ...[
          SectionHeader(
            title: 'Clinical categories',
            subtitle: 'Browse current publication program areas',
            icon: LucideIcons.layoutGrid,
            onSeeAll: () => context.push(AppRoutes.publicGuidelines),
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final area in areas)
                ActionChip(
                  avatar: const Icon(LucideIcons.bookOpen, size: 18),
                  label: Text(area),
                  onPressed: () => context.push(AppRoutes.publicGuidelines),
                ),
            ],
          ),
          AppSpacing.gapLg,
        ],
        SectionHeader(
          title: 'Latest guidance',
          subtitle: 'Recently published or updated',
          icon: LucideIcons.bookOpenText,
          onSeeAll: () => context.push(AppRoutes.publicGuidelines),
        ),
        AppSpacing.gapSm,
        for (final publication in publications.take(4))
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const ClinicalIconTile(icon: LucideIcons.fileText),
              title: Text(publication.title),
              subtitle: Text(
                [
                      publication.sourceOrganization,
                      publication.version.isEmpty
                          ? null
                          : 'v${publication.version}',
                    ]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () =>
                  context.push(AppRoutes.publicGuideline(publication.id)),
            ),
          ),
      ],
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});
  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 360;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width >= 600 ? 6 : 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: largeText
            ? 154
            : narrow
            ? 108
            : 104,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(action.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      action.icon,
                      size: 19,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PublicationSkeleton extends StatelessWidget {
  const _PublicationSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < 3; index++)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            height: 72,
            child: Center(
              child: LinearProgressIndicator(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
        ),
    ],
  );
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(LucideIcons.cloudOff),
      title: const Text('Latest guidance is unavailable'),
      subtitle: const Text('Other sections remain available.'),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
