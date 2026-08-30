part of '../screens/all_actions_page.dart';

class _ActionsHeaderCard extends StatelessWidget {
  const _ActionsHeaderCard({
    required this.clinicalToolsCount,
    required this.referencesCount,
    required this.contentCount,
  });

  final int clinicalToolsCount;
  final int referencesCount;
  final int contentCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final total = clinicalToolsCount + referencesCount + contentCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(LucideIcons.layoutGrid, color: cs.primary, size: 28),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Actions',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quick access to everything you can do in MediGuide.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _CountChip(label: '$total total', icon: LucideIcons.layers),
                    if (clinicalToolsCount > 0)
                      _CountChip(
                        label: '$clinicalToolsCount tools',
                        icon: LucideIcons.stethoscope,
                      ),
                    if (referencesCount > 0)
                      _CountChip(
                        label: '$referencesCount reference',
                        icon: LucideIcons.sparkles,
                      ),
                    if (contentCount > 0)
                      _CountChip(
                        label: '$contentCount pages',
                        icon: LucideIcons.files,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
