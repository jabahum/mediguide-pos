part of '../screens/offline_content_page.dart';

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({required this.items});

  final List<OfflineDownload> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final ready = items
        .where((item) => item.status == OfflineDownloadStatus.ready)
        .toList(growable: false);

    final updates = items.where(
      (item) => item.status == OfflineDownloadStatus.updateAvailable,
    );

    final bytes = ready.fold<int>(0, (sum, item) => sum + item.sizeBytes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.hardDrive, color: colors.primary, size: 23),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ready.length} ${ready.length == 1 ? 'item' : 'items'} available offline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_formatBytes(bytes)} stored on this device',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                if (updates.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${updates.length} ${updates.length == 1 ? 'update' : 'updates'} available',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SECTION HEADING
// ===========================================================================
