part of '../screens/offline_content_page.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OfflineDownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (label, color) = switch (status) {
      OfflineDownloadStatus.queued => ('Queued', colors.primary),
      OfflineDownloadStatus.downloading => ('Downloading', colors.primary),
      OfflineDownloadStatus.ready => ('Verified', colors.tertiary),
      OfflineDownloadStatus.failed => ('Failed', colors.error),
      OfflineDownloadStatus.canceled => ('Canceled', colors.onSurfaceVariant),
      OfflineDownloadStatus.corrupted => ('Corrupted', colors.error),
      OfflineDownloadStatus.updateAvailable => (
        'Update available',
        colors.primary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ===========================================================================
// METADATA CHIP
// ===========================================================================
