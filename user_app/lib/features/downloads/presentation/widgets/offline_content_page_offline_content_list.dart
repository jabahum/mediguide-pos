part of '../screens/offline_content_page.dart';

class _OfflineContentList extends StatelessWidget {
  const _OfflineContentList({
    required this.items,
    required this.onRefresh,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
  });

  final List<OfflineDownload> items;
  final Future<void> Function() onRefresh;
  final ValueChanged<OfflineDownload> onCancel;
  final ValueChanged<OfflineDownload> onRetry;
  final ValueChanged<OfflineDownload> onRemove;

  @override
  Widget build(BuildContext context) {
    final ready = items
        .where((item) => item.status == OfflineDownloadStatus.ready)
        .toList(growable: false);

    final active = items
        .where(
          (item) =>
              item.status == OfflineDownloadStatus.queued ||
              item.status == OfflineDownloadStatus.downloading,
        )
        .toList(growable: false);

    final needsAttention = items
        .where(
          (item) =>
              item.status == OfflineDownloadStatus.failed ||
              item.status == OfflineDownloadStatus.canceled ||
              item.status == OfflineDownloadStatus.corrupted ||
              item.status == OfflineDownloadStatus.updateAvailable,
        )
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxxl,
        ),
        children: [
          _StorageSummary(items: items),

          if (active.isNotEmpty) ...[
            AppSpacing.gapXl,
            const _SectionHeading(
              title: 'Downloading',
              subtitle: 'Offline copies currently being prepared.',
              icon: LucideIcons.download,
            ),
            AppSpacing.gapSm,
            for (final item in active)
              _DownloadTile(
                item: item,
                onCancel: () {
                  onCancel(item);
                },
                onRetry: () {
                  onRetry(item);
                },
                onRemove: () {
                  onRemove(item);
                },
              ),
          ],

          if (needsAttention.isNotEmpty) ...[
            AppSpacing.gapXl,
            const _SectionHeading(
              title: 'Needs attention',
              subtitle: 'Downloads with updates, errors or incomplete files.',
              icon: LucideIcons.triangleAlert,
            ),
            AppSpacing.gapSm,
            for (final item in needsAttention)
              _DownloadTile(
                item: item,
                onCancel: () {
                  onCancel(item);
                },
                onRetry: () {
                  onRetry(item);
                },
                onRemove: () {
                  onRemove(item);
                },
              ),
          ],

          if (ready.isNotEmpty) ...[
            AppSpacing.gapXl,
            const _SectionHeading(
              title: 'Available offline',
              subtitle: 'Verified content stored on this device.',
              icon: LucideIcons.circleCheck,
            ),
            AppSpacing.gapSm,
            for (final item in ready)
              _DownloadTile(
                item: item,
                onCancel: () {
                  onCancel(item);
                },
                onRetry: () {
                  onRetry(item);
                },
                onRemove: () {
                  onRemove(item);
                },
              ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// STORAGE SUMMARY
// ===========================================================================
