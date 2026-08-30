part of '../screens/publication_guideline_page.dart';

class _GuidelineAbout extends StatelessWidget {
  const _GuidelineAbout({
    required this.publication,
    required this.recommendations,
  });

  final GuidelinePublication publication;

  final List<CalloutGuidelineBlock> recommendations;

  @override
  Widget build(BuildContext context) {
    final facts = <(String, String)>[
      ('Purpose', publication.description),
      ('Target users', publication.intendedPopulation),
      ('Applies to', publication.healthcareLevel),
      ('Language', publication.language),
      ('Program area', publication.programArea),
      ('Review date', publication.reviewDate),
    ].where((item) => item.$2.trim().isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this guideline',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        AppSpacing.gapLg,

        for (final fact in facts) ...[
          Text(
            fact.$1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            fact.$2,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),

          AppSpacing.gapLg,
        ],

        if (recommendations.isNotEmpty) ...[
          Text(
            'Key recommendations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),

          AppSpacing.gapSm,

          for (final block in recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  AppSpacing.hGapSm,

                  Expanded(child: Text(block.payload.content)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// =============================================================================
// CHAPTERS
// =============================================================================
