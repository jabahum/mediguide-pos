part of '../screens/ai_assistant_page.dart';

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
