import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/downloads/presentation/controllers/guideline_downloads_controller.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

part '../widgets/offline_content_page_offline_content_list.dart';
part '../widgets/offline_content_page_storage_summary.dart';
part '../widgets/offline_content_page_section_heading.dart';
part '../widgets/offline_content_page_download_tile.dart';
part '../widgets/offline_content_page_status_chip.dart';
part '../widgets/offline_content_page_metadata_chip.dart';
part '../widgets/offline_content_page_download_action.dart';
part '../widgets/offline_content_page_offline_loading.dart';
part '../widgets/offline_content_page_centered_message.dart';

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
              AppMessage.info(context, 'Download canceled.');
            },
            onRetry: (item) async {
              try {
                await ref
                    .read(guidelineDownloadsControllerProvider.notifier)
                    .retry(item);
                if (context.mounted) {
                  AppMessage.success(context, 'Offline copy downloaded.');
                }
              } catch (_) {
                if (context.mounted) {
                  AppMessage.error(
                    context,
                    'The download could not be restarted. Please try again.',
                  );
                }
              }
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

    try {
      await ref
          .read(guidelineDownloadsControllerProvider.notifier)
          .remove(item);
      if (context.mounted) {
        AppMessage.success(context, 'Offline copy removed.');
      }
    } catch (_) {
      if (context.mounted) {
        AppMessage.error(
          context,
          'The offline copy could not be removed. Please try again.',
        );
      }
    }
  }
}

// ===========================================================================
// CONTENT LIST
// ===========================================================================
