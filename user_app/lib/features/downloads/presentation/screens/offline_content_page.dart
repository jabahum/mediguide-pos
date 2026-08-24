import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/downloads/presentation/controllers/guideline_downloads_controller.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

class OfflineContentPage extends ConsumerWidget {
  const OfflineContentPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(guidelineDownloadsControllerProvider);

    final body = SafeArea(
      top: embedded,
      child: downloads.when(
        loading: () => const _OfflineLoading(),
        error: (_, _) => _CenteredMessage(
          icon: LucideIcons.cloudOff,
          title: 'Offline content is unavailable',
          message:
              'Local download information could not be read from this device.',
          action: FilledButton.tonalIcon(
            onPressed: () {
              ref.invalidate(guidelineDownloadsControllerProvider);
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Try again'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _CenteredMessage(
              icon: LucideIcons.cloudDownload,
              title: 'No offline content yet',
              message:
                  'Open a guideline and download an offline copy to access it without a connection.',
            );
          }

          return _OfflineContentList(
            items: items,
            onRefresh: () async {
              final _ = await ref.refresh(
                guidelineDownloadsControllerProvider.future,
              );
            },
            onCancel: (item) {
              ref
                  .read(guidelineDownloadsControllerProvider.notifier)
                  .cancel(item);
            },
            onRetry: (item) {
              ref
                  .read(guidelineDownloadsControllerProvider.notifier)
                  .retry(item);
            },
            onRemove: (item) {
              _confirmRemove(context, ref, item);
            },
          );
        },
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline Content',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Downloaded guidelines and documents',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    OfflineDownload item,
  ) async {
    final title = item.title.trim().isEmpty
        ? 'Downloaded guideline'
        : item.title.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(LucideIcons.trash2),
          title: const Text('Remove offline copy?'),
          content: Text(
            '“$title” will be removed from this device. '
            'You can download it again later.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(guidelineDownloadsControllerProvider.notifier).remove(item);
  }
}

// ===========================================================================
// CONTENT LIST
// ===========================================================================

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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.primary),

        AppSpacing.hGapSm,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// DOWNLOAD TILE
// ===========================================================================

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

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

enum _DownloadAction { retry, remove }

// ===========================================================================
// LOADING
// ===========================================================================

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

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClinicalIconTile(icon: icon, size: 72, iconSize: 34),

              AppSpacing.gapLg,

              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),

              AppSpacing.gapSm,

              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),

              if (action != null) ...[AppSpacing.gapLg, action!],
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// FILE SIZE
// ===========================================================================

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
