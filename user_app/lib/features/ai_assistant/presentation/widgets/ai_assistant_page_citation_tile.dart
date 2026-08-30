part of '../screens/ai_assistant_page.dart';

class _CitationTile extends StatelessWidget {
  const _CitationTile({
    required this.index,
    required this.citation,
    required this.onTap,
  });

  final int index;
  final RagCitation citation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final navigable = citation.guidelineId.trim().isNotEmpty;

    return ListTile(
      dense: true,
      enabled: navigable,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.primary,
        child: Text(
          '${index + 1}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        citation.displayLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        navigable
            ? 'Open cited guideline section'
            : 'Source navigation unavailable',
      ),
      trailing: navigable
          ? const Icon(LucideIcons.chevronRight, size: 18)
          : Icon(LucideIcons.lock, size: 16, color: colors.onSurfaceVariant),
      onTap: navigable ? onTap : null,
    );
  }
}
