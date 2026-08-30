part of '../screens/my_library_page.dart';

class _LibraryQuickStats extends StatelessWidget {
  const _LibraryQuickStats({
    required this.bookmarks,
    required this.downloads,
    required this.history,
  });

  final int bookmarks;
  final int downloads;
  final int history;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LibraryStat(
            icon: LucideIcons.bookmark,
            value: bookmarks,
            label: 'Saved',
          ),
        ),

        AppSpacing.hGapSm,

        Expanded(
          child: _LibraryStat(
            icon: LucideIcons.download,
            value: downloads,
            label: 'Offline',
          ),
        ),

        AppSpacing.hGapSm,

        Expanded(
          child: _LibraryStat(
            icon: LucideIcons.bookOpenText,
            value: history,
            label: 'Read',
          ),
        ),
      ],
    );
  }
}
