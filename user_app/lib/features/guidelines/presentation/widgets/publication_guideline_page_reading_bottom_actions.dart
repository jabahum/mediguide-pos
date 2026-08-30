part of '../screens/publication_guideline_page.dart';

class _ReadingBottomActions extends StatelessWidget {
  const _ReadingBottomActions({
    required this.isBookmarked,
    required this.onAskAi,
    required this.onBookmark,
    required this.onNotes,
    required this.onMore,
  });

  final bool isBookmarked;

  final VoidCallback onAskAi;
  final VoidCallback onBookmark;
  final VoidCallback onNotes;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReaderBottomAction(
            icon: LucideIcons.sparkles,
            label: 'Ask AI',
            onTap: onAskAi,
          ),
        ),

        Expanded(
          child: _ReaderBottomAction(
            icon: LucideIcons.notebookPen,
            label: 'Notes',
            onTap: onNotes,
          ),
        ),

        Expanded(
          child: _ReaderBottomAction(
            icon: isBookmarked
                ? LucideIcons.bookmarkCheck
                : LucideIcons.bookmark,
            label: 'Bookmark',
            onTap: onBookmark,
          ),
        ),

        Expanded(
          child: _ReaderBottomAction(
            icon: LucideIcons.ellipsis,
            label: 'More',
            onTap: onMore,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BOTTOM ICON ACTION
// =============================================================================
