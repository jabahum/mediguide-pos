part of '../screens/offline_content_page.dart';

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({
    required this.item,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
  });

  final OfflineDownload item;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final active =
        item.status == OfflineDownloadStatus.queued ||
        item.status == OfflineDownloadStatus.downloading;

    final ready = item.status == OfflineDownloadStatus.ready;

    final updateAvailable =
        item.status == OfflineDownloadStatus.updateAvailable;

    final title = item.title.trim().isEmpty
        ? 'Downloaded guideline'
        : item.title.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: updateAvailable
              ? colors.primary.withValues(alpha: 0.4)
              : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ready
              ? () {
                  context.push(AppRoutes.publicGuideline(item.guidelineId));
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClinicalIconTile(
                  icon: _icon(item.status),
                  color: _statusColor(context, item.status),
                  backgroundColor: _statusColor(
                    context,
                    item.status,
                  ).withValues(alpha: 0.10),
                ),

                AppSpacing.hGapMd,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),

                          if (ready)
                            const Padding(
                              padding: EdgeInsets.only(left: AppSpacing.xs),
                              child: Icon(LucideIcons.chevronRight, size: 18),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetadataChip(
                            label: switch (item.assetType) {
                              'original_pdf' => 'Original PDF',
                              'outbreak_document' => 'Outbreak document',
                              _ => 'Offline package',
                            },
                          ),

                          if (item.version.trim().isNotEmpty)
                            _MetadataChip(label: 'v${item.version}'),

                          if (item.sizeBytes > 0)
                            _MetadataChip(label: _formatBytes(item.sizeBytes)),

                          _StatusChip(status: item.status),
                        ],
                      ),

                      if (active) ...[
                        AppSpacing.gapSm,

                        LinearProgressIndicator(
                          value: item.progress > 0
                              ? item.progress.clamp(0.0, 1.0)
                              : null,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          item.progress > 0
                              ? '${(item.progress.clamp(0.0, 1.0) * 100).round()}% downloaded'
                              : item.status == OfflineDownloadStatus.queued
                              ? 'Waiting to download'
                              : 'Downloading...',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],

                      if (item.error.trim().isNotEmpty) ...[
                        AppSpacing.gapSm,

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.error.trim(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onErrorContainer),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                AppSpacing.hGapXs,

                active
                    ? IconButton(
                        tooltip: 'Cancel download',
                        onPressed: onCancel,
                        icon: const Icon(LucideIcons.x),
                      )
                    : PopupMenuButton<_DownloadAction>(
                        tooltip: 'Download actions',
                        onSelected: (action) {
                          switch (action) {
                            case _DownloadAction.retry:
                              onRetry();
                            case _DownloadAction.remove:
                              onRemove();
                          }
                        },
                        itemBuilder: (_) => [
                          if (!ready || updateAvailable)
                            PopupMenuItem(
                              value: _DownloadAction.retry,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  updateAvailable
                                      ? LucideIcons.refreshCw
                                      : LucideIcons.rotateCcw,
                                ),
                                title: Text(
                                  updateAvailable
                                      ? 'Download update'
                                      : 'Retry download',
                                ),
                              ),
                            ),
                          const PopupMenuItem(
                            value: _DownloadAction.remove,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(LucideIcons.trash2),
                              title: Text('Remove from device'),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _icon(OfflineDownloadStatus status) {
    return switch (status) {
      OfflineDownloadStatus.queued => LucideIcons.clock3,
      OfflineDownloadStatus.downloading => LucideIcons.download,
      OfflineDownloadStatus.ready => LucideIcons.circleCheck,
      OfflineDownloadStatus.failed => LucideIcons.triangleAlert,
      OfflineDownloadStatus.canceled => LucideIcons.circleX,
      OfflineDownloadStatus.corrupted => LucideIcons.shieldAlert,
      OfflineDownloadStatus.updateAvailable => LucideIcons.refreshCw,
    };
  }

  static Color _statusColor(
    BuildContext context,
    OfflineDownloadStatus status,
  ) {
    final colors = Theme.of(context).colorScheme;

    return switch (status) {
      OfflineDownloadStatus.ready => colors.tertiary,
      OfflineDownloadStatus.failed ||
      OfflineDownloadStatus.corrupted => colors.error,
      OfflineDownloadStatus.updateAvailable => colors.primary,
      OfflineDownloadStatus.canceled => colors.onSurfaceVariant,
      OfflineDownloadStatus.queued ||
      OfflineDownloadStatus.downloading => colors.primary,
    };
  }
}

// ===========================================================================
// STATUS CHIP
// ===========================================================================
