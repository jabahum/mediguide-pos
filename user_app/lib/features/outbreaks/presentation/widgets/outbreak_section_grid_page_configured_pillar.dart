part of '../screens/outbreak_section_grid_page.dart';

class _ConfiguredPillarGrid extends StatelessWidget {
  const _ConfiguredPillarGrid({required this.pillar, required this.detail});

  final PublicOutbreakPillar pillar;
  final PublicOutbreakDetail detail;

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[];
    for (final child in pillar.children) {
      entries.add(
        _ConfiguredPillarCard(
          title: child.name,
          description: child.description,
          icon: _configuredSectionIcon(child.icon, child.slug),
          onTap: () => context.push(
            AppRoutes.outbreakSectionFor(detail.outbreak.id, child.slug),
          ),
        ),
      );
    }
    for (final item in pillar.items) {
      entries.add(
        _ConfiguredPillarCard(
          title: _configuredItemTitle(item),
          description: item.description,
          icon: _configuredSectionIcon(item.icon, item.contentType),
          onTap: () => _openConfiguredItem(context, item, detail),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          pillar.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (pillar.description.isNotEmpty) ...[
          AppSpacing.gapXs,
          Text(
            pillar.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        AppSpacing.gapLg,
        if (entries.isEmpty)
          const Center(child: Text('No published resources are available.'))
        else
          for (final entry in entries) ...[entry, AppSpacing.gapSm],
      ],
    );
  }
}

class _ConfiguredPillarCard extends StatelessWidget {
  const _ConfiguredPillarCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onTap,
      leading: ClinicalIconTile(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: description.isEmpty ? null : Text(description),
      trailing: const Icon(LucideIcons.chevronRight, size: 19),
    ),
  );
}

String _configuredItemTitle(PublicOutbreakPillarItem item) {
  if (item.label.trim().isNotEmpty) return item.label.trim();
  return switch (item.contentType) {
    'outbreak_document' || 'form' => 'Open guidance document',
    'situation_report' => 'Open situation report',
    'guideline' => 'Open clinical guideline',
    'algorithm' => 'Open algorithm',
    'clinical_tool' => 'Open clinical tool',
    'drug_reference' => 'Open medicine reference',
    _ => 'Open resource',
  };
}

IconData _configuredSectionIcon(String configured, String fallback) {
  final value = configured.isEmpty ? fallback : configured;
  return switch (value) {
    'outbreak_document' ||
    'guideline' ||
    'form' ||
    'file-text' => LucideIcons.fileText,
    'situation_report' || 'file-chart' => LucideIcons.fileChartColumn,
    'algorithm' => LucideIcons.gitBranch,
    'clinical_tool' => LucideIcons.calculator,
    'drug_reference' || 'pill' => LucideIcons.pill,
    _ => LucideIcons.folderOpen,
  };
}

Future<void> _openConfiguredItem(
  BuildContext context,
  PublicOutbreakPillarItem item,
  PublicOutbreakDetail detail,
) async {
  if (item.contentType == 'outbreak_document' || item.contentType == 'form') {
    final matches = detail.documents.where(
      (value) => value.id == item.contentId,
    );
    if (matches.isNotEmpty) {
      final document = matches.first;
      context.push(
        AppRoutes.outbreakDocument(document.outbreakId, document.id),
        extra: document,
      );
      return;
    }
    if (item.contentId.isNotEmpty) {
      context.push(
        AppRoutes.outbreakDocument(detail.outbreak.id, item.contentId),
      );
      return;
    }
  }
  if (item.contentType == 'situation_report') {
    context.push(AppRoutes.situationReport(item.contentId));
    return;
  }
  if (item.contentType == 'guideline') {
    context.push(AppRoutes.publicGuideline(item.contentId));
    return;
  }
  if (item.contentType == 'clinical_tool') {
    context.push(AppRoutes.calculator(item.contentId));
    return;
  }
  if (item.contentType == 'internal_route' && AppRoutes.isPublic(item.target)) {
    context.push(item.target);
    return;
  }
  final uri = Uri.tryParse(item.target);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  }
  if (context.mounted) {
    AppMessage.info(
      context,
      'This resource does not yet have a supported reader.',
    );
  }
}
