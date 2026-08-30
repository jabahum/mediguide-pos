part of '../screens/my_library_page.dart';

final class LibraryData {
  const LibraryData({
    required this.bookmarks,
    required this.history,
    required this.publications,
    required this.collections,
    required this.downloads,
  });

  final List<ReadingProgress> bookmarks;
  final List<ReadingProgress> history;

  final Map<String, GuidelinePublication> publications;

  final List<GuidelineCollectionSummary> collections;

  final List<GuidelineDownloadRecord> downloads;
}
