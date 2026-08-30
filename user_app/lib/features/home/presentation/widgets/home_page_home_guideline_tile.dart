part of '../screens/home_page.dart';

class _HomeGuidelineTile extends StatelessWidget {
  const _HomeGuidelineTile({
    required this.title,
    required this.category,
    required this.updatedAt,
    required this.onTap,
  });

  final String title;
  final String category;
  final String updatedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    LucideIcons.fileText,
                    color: colors.primary,
                    size: 21,
                  ),
                ),

                AppSpacing.md.gap,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),

                      if (category.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),

                        _GuidelineCategoryChip(label: category),
                      ],

                      const SizedBox(height: 7),

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
                              updatedAt,
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

                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 19,
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
