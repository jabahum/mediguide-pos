part of '../screens/home_page.dart';

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final value = progress.progressPercentage.clamp(0.0, 1.0);

    final percent = (value * 100).round();

    return Semantics(
      button: true,
      label: 'Continue reading. $percent percent complete.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    LucideIcons.bookOpenText,
                    color: colors.primary,
                    size: 22,
                  ),
                ),

                AppSpacing.md.gap,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Continue guideline',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '$percent%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock3,
                            size: 13,
                            color: colors.onSurfaceVariant,
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              progress.lastReadFormatted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                AppSpacing.sm.gap,

                Icon(
                  LucideIcons.chevronRight,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// RECENT GUIDELINES
/// ===========================================================================
