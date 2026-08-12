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
            tooltip: 'About MediGuide',
            onPressed: () => context.push(AppRoutes.aboutUs),
            icon: const Icon(LucideIcons.info),
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
              header: true,
              child: Text(
                'Trusted clinical guidance',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              'Search published guidance and clinical reference tools. Sign in to sync private bookmarks, notes and reading progress.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.gapMd,
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
            const SectionHeader(
              title: 'Emergency care',
              subtitle: 'Fast access to essential clinical references',
              icon: LucideIcons.siren,
            ),
            AppSpacing.gapSm,
            _QuickActionGrid(
              actions: [
                _QuickAction(
                  'Guidelines',
                  LucideIcons.bookOpenText,
                  AppRoutes.publicGuidelines,
                ),
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
                  'Facilities',
                  LucideIcons.hospital,
                  AppRoutes.healthFacilities,
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
                const Icon(LucideIcons.siren),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    'Active public update',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(outbreak.status),
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
              leading: const CircleAvatar(
                child: Icon(LucideIcons.fileText, size: 20),
              ),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: narrow
            ? 1
            : width >= 600
            ? 4
            : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: narrow ? 4.5 : 2.3,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(action.route),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(action.icon),
                  const SizedBox(width: 8),
                  Expanded(child: Text(action.label)),
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
