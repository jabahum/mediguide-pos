part of '../screens/publication_guideline_page.dart';

class _ReaderActionBar extends StatelessWidget {
  const _ReaderActionBar({
    required this.isBookmarked,
    required this.offlineDownload,
    required this.showRead,
    required this.onRead,
    required this.onAskAi,
    required this.onBookmark,
    required this.onNotes,
    required this.onShare,
    required this.onOriginal,
    required this.onDownload,
  });

  final bool isBookmarked;
  final OfflineDownload? offlineDownload;
  final bool showRead;

  final VoidCallback onRead;
  final VoidCallback onAskAi;
  final VoidCallback onBookmark;
  final VoidCallback onNotes;
  final VoidCallback onShare;
  final VoidCallback onOriginal;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: showRead
              ? _OverviewBottomActions(
                  isBookmarked: isBookmarked,
                  offlineDownload: offlineDownload,
                  onRead: onRead,
                  onBookmark: onBookmark,
                  onDownload: onDownload,
                  onMore: () {
                    _showMoreActions(context);
                  },
                )
              : _ReadingBottomActions(
                  isBookmarked: isBookmarked,
                  onAskAi: onAskAi,
                  onBookmark: onBookmark,
                  onNotes: onNotes,
                  onMore: () {
                    _showMoreActions(context);
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _showMoreActions(BuildContext context) {
    final status = offlineDownload?.status;
    final downloading =
        status == OfflineDownloadStatus.queued ||
        status == OfflineDownloadStatus.downloading;
    final offlineTitle = switch (status) {
      OfflineDownloadStatus.ready => 'Manage offline copy',
      OfflineDownloadStatus.updateAvailable => 'Update offline copy',
      OfflineDownloadStatus.failed ||
      OfflineDownloadStatus.corrupted => 'Retry offline copy',
      OfflineDownloadStatus.queued ||
      OfflineDownloadStatus.downloading => 'Downloading offline copy',
      _ => 'Download for offline use',
    };
    final offlineSubtitle = switch (status) {
      OfflineDownloadStatus.ready => 'Saved and available without internet',
      OfflineDownloadStatus.updateAvailable =>
        'A newer published version is available',
      OfflineDownloadStatus.failed || OfflineDownloadStatus.corrupted =>
        'The previous download did not complete',
      OfflineDownloadStatus.queued ||
      OfflineDownloadStatus.downloading => 'The verified file is being saved',
      _ => 'Save a verified copy on this device',
    };
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: [
              ListTile(
                leading: const Icon(LucideIcons.sparkles),
                title: const Text('Ask AI'),
                subtitle: const Text(
                  'Ask questions using this guideline as context',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onAskAi();
                },
              ),

              ListTile(
                leading: const Icon(LucideIcons.notebookPen),
                title: const Text('Reading notes'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onNotes();
                },
              ),

              ListTile(
                leading: const Icon(LucideIcons.share2),
                title: const Text('Share guideline'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onShare();
                },
              ),

              ListTile(
                leading: const Icon(LucideIcons.fileText),
                title: const Text('Open original document'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onOriginal();
                },
              ),

              ListTile(
                leading: Icon(
                  status == OfflineDownloadStatus.ready
                      ? LucideIcons.cloudCheck
                      : status == OfflineDownloadStatus.updateAvailable
                      ? LucideIcons.refreshCw
                      : LucideIcons.download,
                ),
                title: Text(offlineTitle),
                subtitle: Text(offlineSubtitle),
                onTap: downloading
                    ? null
                    : () {
                        Navigator.pop(sheetContext);

                        onDownload();
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// OVERVIEW BOTTOM ACTIONS
// =============================================================================
