import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/widgets/app_skeleton.dart';
import 'package:user_app/features/discovery/data/models/discovery_models.dart';

class DiseaseDirectoryPage extends ConsumerStatefulWidget {
  const DiseaseDirectoryPage({super.key});
  @override
  ConsumerState<DiseaseDirectoryPage> createState() =>
      _DiseaseDirectoryPageState();
}

class _DiseaseDirectoryPageState extends ConsumerState<DiseaseDirectoryPage> {
  final search = TextEditingController();
  late Future<DiscoveryValue<List<DiscoveryDisease>>> request;
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reload() => request = ref
      .read(discoveryRepositoryProvider)
      .diseases(search: search.text);
  @override
  Widget build(BuildContext context) {
    if (!ref.watch(diseaseTaxonomyEnabledProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diseases & conditions')),
        body: const EmptyState('Disease discovery is not enabled yet.'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Diseases & conditions')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(reload);
          await request;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search),
                hintText: 'Search official names or aliases',
              ),
              onSubmitted: (_) => setState(reload),
            ),
            const SizedBox(height: 16),
            FutureBuilder<DiscoveryValue<List<DiscoveryDisease>>>(
              future: request,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const DiscoverySkeleton();
                }
                if (snapshot.hasError) {
                  return ErrorState(onRetry: () => setState(reload));
                }
                final result = snapshot.data!;
                if (result.offline) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      AppMessage.warning(
                        context,
                        'Offline: showing saved disease content.',
                      );
                    }
                  });
                }
                if (result.value.isEmpty) {
                  return const EmptyState(
                    'No active diseases with public content found.',
                  );
                }
                return Column(children: diseaseTiles(context, result.value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DiseaseDetailPage extends ConsumerStatefulWidget {
  const DiseaseDetailPage({required this.slug, super.key});
  final String slug;

  @override
  ConsumerState<DiseaseDetailPage> createState() => _DiseaseDetailPageState();
}

class _DiseaseDetailPageState extends ConsumerState<DiseaseDetailPage> {
  late Future<DiscoveryValue<DiscoveryDisease>> request;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() =>
      request = ref.read(discoveryRepositoryProvider).disease(widget.slug);

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(diseaseTaxonomyEnabledProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Disease')),
        body: const EmptyState('Disease discovery is not enabled yet.'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Disease')),
      body: FutureBuilder<DiscoveryValue<DiscoveryDisease>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DiscoverySkeleton();
        }
        if (snapshot.hasError) {
          return ErrorState(onRetry: () => setState(reload));
        }
        final disease = snapshot.data!.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              disease.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (disease.description.isNotEmpty) Text(disease.description),
            if (snapshot.data!.offline)
              const Card(
                child: ListTile(
                  leading: Icon(LucideIcons.cloudOff),
                  title: Text('Showing saved disease content'),
                ),
              ),
            if (disease.aliases.isNotEmpty)
              Text('Also known as: ${disease.aliases.join(', ')}'),
            if (disease.children.isNotEmpty) ...[
              const SectionHeading('Related conditions'),
              ...disease.children.map(
                (item) => ListTile(
                  title: Text(item.name),
                  onTap: () => context.push(AppRoutes.disease(item.slug)),
                ),
              ),
            ],
            if (ref.watch(diseaseHubsEnabledProvider)) ...[
              const SectionHeading('Content hubs'),
              if (disease.hubs.isEmpty)
                const Text('No dedicated hub is currently published.')
              else
                ...disease.hubs.map((hub) => HubTile(hub)),
            ],
            const SectionHeading('Approved resources'),
            if (disease.resources.isEmpty)
              const Text('No public resources are currently available.')
            else
              ...disease.resources.map((item) => ResourceTile(item)),
          ],
        );
      },
      ),
    );
  }
}

class ContentHubPage extends ConsumerStatefulWidget {
  const ContentHubPage({required this.slug, super.key});
  final String slug;

  @override
  ConsumerState<ContentHubPage> createState() => _ContentHubPageState();
}

class _ContentHubPageState extends ConsumerState<ContentHubPage> {
  late Future<DiscoveryValue<DiscoveryHub>> request;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() =>
      request = ref.read(discoveryRepositoryProvider).hub(widget.slug);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Content hub')),
    body: FutureBuilder<DiscoveryValue<DiscoveryHub>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DiscoverySkeleton();
        }
        if (snapshot.hasError) {
          return ErrorState(onRetry: () => setState(reload));
        }
        final hub = snapshot.data!.value;
        final enabled = hub.diseases.isEmpty
            ? ref.watch(genericHubsEnabledProvider)
            : ref.watch(diseaseHubsEnabledProvider);
        if (!enabled) {
          return const EmptyState('This content hub is not enabled yet.');
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              hub.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (hub.description.isNotEmpty) Text(hub.description),
            if (hub.diseases.isNotEmpty)
              Wrap(
                spacing: 8,
                children: hub.diseases
                    .map(
                      (disease) => ActionChip(
                        label: Text(disease.name),
                        onPressed: () =>
                            context.push(AppRoutes.disease(disease.slug)),
                      ),
                    )
                    .toList(),
              ),
            if (snapshot.data!.offline)
              const Card(
                child: ListTile(
                  leading: Icon(LucideIcons.cloudOff),
                  title: Text('Showing saved hub content'),
                ),
              ),
            if (hub.outbreak != null) OutbreakBanner(hub.outbreak!),
            const SectionHeading('Quick access'),
            if (hub.pillars.isEmpty)
              const EmptyState('This hub has no published sections yet.')
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
                children: hub.pillars
                    .map(
                      (pillar) => InkWell(
                        onTap: () => context.push(
                          AppRoutes.hubPillar(hub.slug, pillar.slug),
                        ),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.folderOpen),
                                Text(
                                  pillar.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text('${pillar.resourceCount} resources'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ...hubResources(hub, featuredOnly: true).isEmpty
                ? const <Widget>[]
                : <Widget>[
                    const SectionHeading('Featured resources'),
                    ...hubResources(
                      hub,
                      featuredOnly: true,
                    ).map(ResourceTile.new),
                  ],
            ...hubResources(hub, contentType: 'situation_report').isEmpty
                ? const <Widget>[]
                : <Widget>[
                    const SectionHeading('Situation reports'),
                    ...hubResources(
                      hub,
                      contentType: 'situation_report',
                    ).map(ResourceTile.new),
                  ],
            ...hubResources(hub).isEmpty
                ? const <Widget>[]
                : <Widget>[
                    const SectionHeading('Latest updates'),
                    ...hubResources(hub).take(5).map(ResourceTile.new),
                  ],
          ],
        );
      },
    ),
  );
}

class ContentPillarPage extends ConsumerStatefulWidget {
  const ContentPillarPage({
    required this.hubSlug,
    required this.pillarSlug,
    super.key,
  });
  final String hubSlug, pillarSlug;
  @override
  ConsumerState<ContentPillarPage> createState() => _ContentPillarPageState();
}

class _ContentPillarPageState extends ConsumerState<ContentPillarPage> {
  String query = '', kind = '';
  late Future<DiscoveryValue<DiscoveryHub>> request;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() =>
      request = ref.read(discoveryRepositoryProvider).hub(widget.hubSlug);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hub section')),
    body: FutureBuilder<DiscoveryValue<DiscoveryHub>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DiscoverySkeleton();
        }
        if (snapshot.hasError) {
          return ErrorState(onRetry: () => setState(reload));
        }
        final hub = snapshot.data?.value;
        if (hub != null) {
          final enabled = hub.diseases.isEmpty
              ? ref.watch(genericHubsEnabledProvider)
              : ref.watch(diseaseHubsEnabledProvider);
          if (!enabled) {
            return const EmptyState('This content hub is not enabled yet.');
          }
        }
        final matches = hub == null
            ? <DiscoveryPillar>[]
            : flatten(
                hub.pillars,
              ).where((item) => item.slug == widget.pillarSlug).toList();
        if (matches.isEmpty) {
          return const EmptyState('This hub section is unavailable.');
        }
        final pillar = matches.first;
        final all = resources(pillar);
        final kinds = all.map((e) => e.contentType).toSet().toList()..sort();
        final shown = all
            .where(
              (item) =>
                  (kind.isEmpty || item.contentType == kind) &&
                  '${item.title} ${item.description}'.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (snapshot.data!.offline)
              const Card(
                child: ListTile(
                  leading: Icon(LucideIcons.cloudOff),
                  title: Text('Showing saved hub content'),
                ),
              ),
            Text(
              pillar.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (pillar.description.isNotEmpty) Text(pillar.description),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search),
                hintText: 'Search this section',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Content type'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('All content types'),
                ),
                ...kinds.map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.replaceAll('_', ' ')),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => kind = value ?? ''),
            ),
            Text('${shown.length} public resources'),
            ...shown.map((item) => ResourceTile(item)),
          ],
        );
      },
    ),
  );
}

class HubTile extends StatelessWidget {
  const HubTile(this.hub, {super.key});
  final DiscoveryHub hub;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(LucideIcons.layoutGrid),
      title: Text(hub.name),
      subtitle: Text(hub.description, maxLines: 2),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: () => context.push(AppRoutes.hub(hub.slug)),
    ),
  );
}

class ResourceTile extends StatelessWidget {
  const ResourceTile(this.resource, {super.key});
  final DiscoveryResource resource;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(LucideIcons.fileText),
      title: Text(resource.title),
      subtitle: Text(
        [
          resource.contentType.replaceAll('_', ' '),
          resource.source,
          if (resource.version.isNotEmpty) 'Version ${resource.version}',
          if (resource.publicationDate.isNotEmpty)
            'Published ${shortDate(resource.publicationDate)}',
          if (resource.effectiveAt.isNotEmpty)
            'Effective ${shortDate(resource.effectiveAt)}',
          if (resource.reviewAt.isNotEmpty)
            'Review ${shortDate(resource.reviewAt)}',
          if (resource.expiresAt.isNotEmpty)
            'Expires ${shortDate(resource.expiresAt)}',
        ].where((e) => e.isNotEmpty).join(' · '),
      ),
      onTap: () {
        final route = mobileRoute(resource);
        if (route == null) {
          return AppMessage.info(
            context,
            'A reader for this resource is not available yet.',
          );
        }
        context.push(route);
      },
    ),
  );
}

class OutbreakBanner extends StatelessWidget {
  const OutbreakBanner(this.value, {super.key});
  final Map<String, dynamic> value;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE OUTBREAK · ${value['status'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            '${value['title'] ?? ''}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('${value['geographic_area'] ?? ''}'),
          if (value['metrics'] is List)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (value['metrics'] as List)
                  .whereType<Map>()
                  .expand(
                    (metric) => metric.entries.map(
                      (entry) => Chip(
                        label: Text(
                          '${entry.value} ${entry.key.toString().replaceAll('_', ' ')}',
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class DiscoverySkeleton extends StatelessWidget {
  const DiscoverySkeleton({super.key});
  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        AppSkeleton(height: 44),
        SizedBox(height: 16),
        AppSkeleton(height: 120),
        SizedBox(height: 12),
        AppSkeleton(height: 120),
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.onRetry, super.key});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

List<DiscoveryPillar> flatten(List<DiscoveryPillar> values) =>
    values.expand((item) => [item, ...flatten(item.children)]).toList();
List<DiscoveryResource> resources(DiscoveryPillar pillar) => [
  ...pillar.items,
  ...pillar.children.expand(resources),
];

List<Widget> diseaseTiles(
  BuildContext context,
  List<DiscoveryDisease> diseases, {
  String parentId = '',
  int depth = 0,
}) {
  final ids = diseases.map((item) => item.id).toSet();
  final rows = parentId.isEmpty
      ? diseases.where(
          (item) => item.parentId.isEmpty || !ids.contains(item.parentId),
        )
      : diseases.where((item) => item.parentId == parentId);
  return [
    for (final disease in rows) ...[
      Padding(
        padding: EdgeInsets.only(left: depth * 18.0),
        child: Card(
          child: ListTile(
            leading: const Icon(LucideIcons.activity),
            title: Text(disease.name),
            subtitle: disease.description.isEmpty
                ? null
                : Text(
                    disease.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => context.push(AppRoutes.disease(disease.slug)),
          ),
        ),
      ),
      ...diseaseTiles(
        context,
        diseases,
        parentId: disease.id,
        depth: depth + 1,
      ),
    ],
  ];
}

String? mobileRoute(DiscoveryResource value) => switch (value.contentType) {
  'guideline' => AppRoutes.publicGuideline(value.id),
  'outbreak' => AppRoutes.outbreak(value.id),
  'situation_report' => AppRoutes.situationReport(value.id),
  'clinical_tool' => AppRoutes.calculator(value.id),
  'drug_reference' => AppRoutes.drugIndex,
  'outbreak_document' || 'form' => outbreakDocumentRoute(value.route),
  'algorithm' => algorithmRoute(value.route, value.id),
  'internal_route' => value.route.startsWith('/') ? value.route : null,
  _ => null,
};

String? outbreakDocumentRoute(String route) {
  final parts = Uri.tryParse(route)?.pathSegments ?? const <String>[];
  if (parts.length >= 4 && parts[0] == 'outbreaks' && parts[2] == 'documents') {
    return AppRoutes.outbreakDocument(parts[1], parts[3]);
  }
  return null;
}

String? algorithmRoute(String route, String blockId) {
  final parts = Uri.tryParse(route)?.pathSegments ?? const <String>[];
  if (parts.length >= 2 && parts[0] == 'guidelines') {
    return AppRoutes.publicGuidelineAlgorithmView(parts[1], blockId);
  }
  return null;
}

String shortDate(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;

List<DiscoveryResource> hubResources(
  DiscoveryHub hub, {
  bool featuredOnly = false,
  String? contentType,
}) {
  final seen = <String>{};
  final result = <DiscoveryResource>[];
  for (final pillar in flatten(hub.pillars)) {
    for (final resource in pillar.items) {
      if (contentType != null && resource.contentType != contentType) continue;
      if (featuredOnly && !resource.featured) continue;
      if (seen.add('${resource.contentType}:${resource.id}')) {
        result.add(resource);
      }
    }
  }
  result.sort(
    (left, right) => right.publicationDate.compareTo(left.publicationDate),
  );
  return result;
}
