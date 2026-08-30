part of '../screens/publication_guideline_page.dart';

class _Overview extends StatelessWidget {
  const _Overview({required this.content});

  final GuidelinePublicationContent content;

  @override
  Widget build(BuildContext context) {
    final publication = content.publication;

    final manifest = content.manifest;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        AppSpacing.lg,
        Responsive.horizontalPadding(context),
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            publication.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),

          if (publication.description.isNotEmpty) ...[
            AppSpacing.gapSm,

            Text(publication.description),
          ],

          AppSpacing.gapMd,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (publication.sourceOrganization.isNotEmpty)
                Chip(label: Text(publication.sourceOrganization)),

              if (publication.version.isNotEmpty)
                Chip(label: Text('Version ${publication.version}')),

              AppStatusBadge(
                icon: manifest.recommendedMode == GuidelineReaderMode.structured
                    ? LucideIcons.badgeCheck
                    : LucideIcons.fileWarning,
                tone: manifest.recommendedMode == GuidelineReaderMode.structured
                    ? AppStatusTone.success
                    : AppStatusTone.warning,
                label:
                    manifest.recommendedMode == GuidelineReaderMode.structured
                    ? 'Reviewed structured content'
                    : 'Partial reviewed content',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ORIGINAL DOCUMENT READER
// =============================================================================
