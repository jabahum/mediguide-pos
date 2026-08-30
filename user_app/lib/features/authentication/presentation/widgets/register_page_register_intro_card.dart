part of '../screens/register_page.dart';

class _RegisterIntroCard extends StatelessWidget {
  const _RegisterIntroCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              LucideIcons.userRoundPlus,
              size: 19,
              color: colors.primary,
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              'Create a professional account to personalize MediGuide and '
              'keep your clinical content synchronized across devices.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORM SECTION
// ============================================================================
