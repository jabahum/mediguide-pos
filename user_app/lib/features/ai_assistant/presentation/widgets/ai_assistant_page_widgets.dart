part of '../screens/ai_assistant_page.dart';

enum _AssistantMenuAction { clearContext }

// ===========================================================================
// TOP CONTEXT
// ===========================================================================

class _AssistantTopContext extends StatelessWidget {
  const _AssistantTopContext({
    required this.currentContext,
    required this.onClearContext,
  });

  final AiContext? currentContext;
  final VoidCallback onClearContext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===============================================================
            // SAFETY
            // ===============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldAlert, size: 17, color: colors.tertiary),

                AppSpacing.hGapSm,

                Expanded(
                  child: Text(
                    'Do not enter patient-identifiable information. '
                    'Verify clinical answers against cited sources and professional judgement.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),

            // ===============================================================
            // CONTEXT
            // ===============================================================
            if (currentContext != null) ...[
              AppSpacing.gapSm,

              Divider(height: 1, color: colors.outlineVariant),

              AppSpacing.gapSm,

              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      LucideIcons.fileText,
                      color: colors.onSecondaryContainer,
                      size: 16,
                    ),
                  ),

                  AppSpacing.hGapSm,

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current guideline context',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentContext!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Clear context',
                    onPressed: onClearContext,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.x, size: 17),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ERROR
// ===========================================================================

class _AssistantErrorBanner extends StatelessWidget {
  const _AssistantErrorBanner({
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            color: colors.onErrorContainer,
            size: 18,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),

          TextButton(
            onPressed: isRetrying ? null : onRetry,
            child: Text(isRetrying ? 'Retrying...' : 'Retry'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SOURCES
// ===========================================================================

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
