part of '../screens/offline_content_page.dart';

class _OfflineLoading extends StatelessWidget {
  const _OfflineLoading();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClinicalIconTile(
              icon: LucideIcons.cloudDownload,
              size: 72,
              iconSize: 34,
            ),

            AppSpacing.gapLg,

            Text(
              'Loading offline content',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),

            AppSpacing.gapSm,

            Text(
              'Checking downloaded guidelines on this device.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),

            AppSpacing.gapLg,

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// EMPTY / ERROR
// ===========================================================================
