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
      child: downloads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CenteredMessage(
          icon: LucideIcons.cloudOff,
          title: 'Offline content is unavailable',
          message: 'Local download metadata could not be read.',
          action: FilledButton.tonal(
            onPressed: () =>
                ref.invalidate(guidelineDownloadsControllerProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const _CenteredMessage(
                icon: LucideIcons.download,
                title: 'No offline content yet',
                message:
                    'Open a guideline and download its verified offline package.',
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(guidelineDownloadsControllerProvider.future),
                child: ListView(
                  padding: AppSpacing.pagePadding,
                  children: [
                    _StorageSummary(items: items),
                    AppSpacing.gapLg,
                    for (final item in items)
                      _DownloadTile(
                        item: item,
                        onCancel: () => ref
                            .read(guidelineDownloadsControllerProvider.notifier)
                            .cancel(item),
                        onRetry: () => ref
                            .read(guidelineDownloadsControllerProvider.notifier)
                            .retry(item),
                        onRemove: () => _confirmRemove(context, ref, item),
                      ),
                  ],
                ),
              ),
      ),
    );
    return embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Offline Content')),
            body: body,
          );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    OfflineDownload item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove download?'),
        content: Text(
          'The downloaded copy of “${item.title}” will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(guidelineDownloadsControllerProvider.notifier)
          .remove(item);
    }
  }
}

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({required this.items});
  final List<OfflineDownload> items;

  @override
  Widget build(BuildContext context) {
    final ready = items.where(
      (item) => item.status == OfflineDownloadStatus.ready,
    );
    final bytes = ready.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(LucideIcons.hardDrive, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ready.length} verified ${ready.length == 1 ? 'download' : 'downloads'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${_formatBytes(bytes)} stored on this device'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final active =
        item.status == OfflineDownloadStatus.queued ||
        item.status == OfflineDownloadStatus.downloading;
    final ready = item.status == OfflineDownloadStatus.ready;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        isThreeLine: active || item.error.isNotEmpty,
        leading: ClinicalIconTile(
          icon: ready ? LucideIcons.check : _icon(item.status),
          color: ready
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.primary,
          backgroundColor: ready
              ? Theme.of(context).colorScheme.tertiaryContainer
              : Theme.of(context).colorScheme.primaryContainer,
        ),
        title: Text(item.title.isEmpty ? 'Downloaded guideline' : item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.assetType == 'original_pdf' ? 'Original document' : 'Offline package'} · v${item.version} · ${_formatBytes(item.sizeBytes)}',
            ),
            if (active) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: item.progress > 0 ? item.progress : null,
              ),
            ],
            if (item.error.isNotEmpty) Text(item.error),
          ],
        ),
        trailing: active
            ? IconButton(
                tooltip: 'Cancel download',
                onPressed: onCancel,
                icon: const Icon(LucideIcons.x),
              )
            : PopupMenuButton<String>(
                tooltip: 'Download actions',
                onSelected: (value) {
                  if (value == 'retry') onRetry();
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  if (!ready ||
                      item.status == OfflineDownloadStatus.updateAvailable)
                    PopupMenuItem(
                      value: 'retry',
                      child: Text(
                        item.status == OfflineDownloadStatus.updateAvailable
                            ? 'Download update'
                            : 'Retry download',
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from device'),
                  ),
                ],
              ),
        onTap: ready
            ? () => context.push(AppRoutes.publicGuideline(item.guidelineId))
            : null,
      ),
    );
  }

  IconData _icon(OfflineDownloadStatus status) => switch (status) {
    OfflineDownloadStatus.queued => LucideIcons.clock,
    OfflineDownloadStatus.downloading => LucideIcons.download,
    OfflineDownloadStatus.ready => LucideIcons.check,
    OfflineDownloadStatus.failed => LucideIcons.triangleAlert,
    OfflineDownloadStatus.canceled => LucideIcons.circleX,
    OfflineDownloadStatus.corrupted => LucideIcons.shieldAlert,
    OfflineDownloadStatus.updateAvailable => LucideIcons.refreshCw,
  };
}

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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          AppSpacing.gapMd,
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.gapSm,
          Text(message, textAlign: TextAlign.center),
          if (action case final action?) ...[AppSpacing.gapMd, action],
        ],
      ),
    ),
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
