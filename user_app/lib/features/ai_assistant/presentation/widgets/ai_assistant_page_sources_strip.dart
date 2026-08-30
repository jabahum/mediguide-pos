part of '../screens/ai_assistant_page.dart';

class _SourcesStrip extends StatelessWidget {
  const _SourcesStrip({required this.citations, required this.onCitation});

  final List<RagCitation> citations;
  final ValueChanged<RagCitation> onCitation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            LucideIcons.bookOpenCheck,
            size: 16,
            color: colors.primary,
          ),
        ),
        title: Text(
          '${citations.length} approved '
          'source${citations.length == 1 ? '' : 's'}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Open the evidence used for the latest answer',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        children: [
          for (var index = 0; index < citations.length; index++)
            _CitationTile(
              index: index,
              citation: citations[index],
              onTap: () {
                onCitation(citations[index]);
              },
            ),
        ],
      ),
    );
  }
}
