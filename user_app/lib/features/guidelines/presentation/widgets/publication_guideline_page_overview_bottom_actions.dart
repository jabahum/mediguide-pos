part of '../screens/publication_guideline_page.dart';

class _OverviewBottomActions extends StatelessWidget {
  const _OverviewBottomActions({
    required this.isBookmarked,
    required this.offlineDownload,
    required this.onRead,
    required this.onBookmark,
    required this.onDownload,
    required this.onMore,
  });

  final bool isBookmarked;
  final OfflineDownload? offlineDownload;

  final VoidCallback onRead;
  final VoidCallback onBookmark;
  final VoidCallback onDownload;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onRead,
            icon: const Icon(LucideIcons.bookOpenText, size: 19),
            label: const Text('Read guideline'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),

        AppSpacing.hGapSm,

        _BottomIconAction(
          icon: isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
          onTap: onBookmark,
        ),

        AppSpacing.hGapXs,

        _BottomIconAction(
          icon: offlineDownload?.status == OfflineDownloadStatus.ready
              ? LucideIcons.cloudCheck
              : LucideIcons.download,
          tooltip: offlineDownload?.status == OfflineDownloadStatus.ready
              ? 'Manage offline copy'
              : 'Download for offline use',
          onTap: onDownload,
        ),

        AppSpacing.hGapXs,

        _BottomIconAction(
          icon: LucideIcons.ellipsis,
          tooltip: 'More',
          onTap: onMore,
        ),
      ],
    );
  }
}

// =============================================================================
// READER BOTTOM ACTIONS
// =============================================================================
