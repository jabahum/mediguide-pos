part of '../screens/my_library_page.dart';

class _LibrarySummary extends StatelessWidget {
  const _LibrarySummary({
    required this.data,
    required this.onBookmarks,
    required this.onNotes,
    required this.onDownloads,
    required this.onHistory,
    required this.onCollections,
    required this.onOfflineUpdates,
    required this.onAiHistory,
  });

  final LibraryData data;

  final VoidCallback onBookmarks;
  final VoidCallback onNotes;
  final VoidCallback onDownloads;
  final VoidCallback onHistory;
  final VoidCallback onCollections;
  final VoidCallback onOfflineUpdates;
  final VoidCallback onAiHistory;

  @override
  Widget build(BuildContext context) {
    final notesCount = data.history
        .where((item) => item.notes.trim().isNotEmpty)
        .length;

    final pendingSyncCount = data.history
        .where((item) => item.pendingSync)
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _LibraryMenuTile(
            icon: LucideIcons.bookmark,
            label: 'Bookmarks',
            description: 'Guidelines saved for quick access',
            count: data.bookmarks.length,
            onTap: onBookmarks,
          ),

          const Divider(height: 1, indent: 64),

          _LibraryMenuTile(
            icon: LucideIcons.notebookPen,
            label: 'Notes',
            description: 'Private notes attached to guidelines',
            count: notesCount,
            onTap: onNotes,
          ),

          const Divider(height: 1, indent: 64),

          _LibraryMenuTile(
            icon: LucideIcons.download,
            label: 'Downloads',
            description: 'Guidelines available without internet',
            count: data.downloads.length,
            onTap: onDownloads,
          ),

          const Divider(height: 1, indent: 64),

          _LibraryMenuTile(
            icon: LucideIcons.history,
            label: 'History',
            description: 'Continue previously opened guidelines',
            count: data.history.length,
            onTap: onHistory,
          ),

          const Divider(height: 1, indent: 64),

          _LibraryMenuTile(
            icon: LucideIcons.folder,
            label: 'Collections',
            description: 'Organize related guidelines',
            count: data.collections.length,
            onTap: onCollections,
          ),

          const Divider(height: 1, indent: 64),

          _LibraryMenuTile(
            icon: LucideIcons.refreshCw,
            label: 'Offline updates',
            description: pendingSyncCount == 0
                ? 'Offline content is synchronized'
                : '$pendingSyncCount item${pendingSyncCount == 1 ? '' : 's'} waiting to synchronize',
            count: pendingSyncCount,
            onTap: onOfflineUpdates,
          ),

          const Divider(height: 1, indent: 64),

          _LibraryMenuTile(
            icon: LucideIcons.sparkles,
            label: 'AI Assistant history',
            description: 'Return to previous clinical conversations',
            onTap: onAiHistory,
          ),
        ],
      ),
    );
  }
}
