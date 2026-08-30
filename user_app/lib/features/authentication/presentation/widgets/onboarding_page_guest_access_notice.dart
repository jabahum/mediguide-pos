part of '../screens/onboarding_page.dart';

class _GuestAccessNotice extends StatelessWidget {
  const _GuestAccessNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Guest access allows public clinical content. Sign in for bookmarks, notes, downloads and synchronization.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.info,
              size: 19,
              color: colors.onSecondaryContainer,
            ),

            AppSpacing.hGapSm,

            Expanded(
              child: Text(
                'Guest access includes public clinical content. '
                'Sign in to sync bookmarks, notes, reading progress '
                'and offline downloads.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
