part of '../screens/edit_profile_page.dart';

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.userX, size: 48, color: colors.onSurfaceVariant),
            AppSpacing.gapMd,
            Text(
              'Profile unavailable',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.gapSm,
            Text(
              'Your profile information could not be loaded.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
