part of '../screens/outbreak_section_grid_page.dart';

class _ClinicalCareGrid extends StatelessWidget {
  const _ClinicalCareGrid({required this.outbreak, required this.documents});

  final PublicOutbreak outbreak;
  final List<PublicOutbreakDocument> documents;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          'Evidence-based clinical management for ${outbreak.diseaseType.isEmpty ? outbreak.title : outbreak.diseaseType}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        AppSpacing.gapLg,
        for (final section in _clinicalCareSections) ...[
          _ClinicalSectionCard(
            section: section,
            document: _documentForKinds(documents, section.documentKinds),
          ),
          AppSpacing.gapSm,
        ],
      ],
    );
  }
}
