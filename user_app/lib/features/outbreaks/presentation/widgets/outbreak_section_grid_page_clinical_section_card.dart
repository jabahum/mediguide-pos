part of '../screens/outbreak_section_grid_page.dart';

class _ClinicalSectionCard extends StatelessWidget {
  const _ClinicalSectionCard({required this.section, required this.document});

  final _ClinicalCareSection section;
  final PublicOutbreakDocument? document;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: document == null
            ? null
            : () => context.push(
                AppRoutes.outbreakDocument(document!.outbreakId, document!.id),
                extra: document,
              ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClinicalIconTile(icon: section.icon),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document == null
                          ? 'No published guidance is currently available'
                          : section.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                document == null
                    ? LucideIcons.circleAlert
                    : LucideIcons.chevronRight,
                size: 19,
                color: document == null
                    ? colors.outline
                    : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
