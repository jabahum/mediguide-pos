part of '../screens/guest_home_page.dart';

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
