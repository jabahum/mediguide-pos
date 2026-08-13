import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/data/models/reading_progress.dart';
import 'package:user_app/features/library/data/models/guideline_library_models.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

final libraryDataProvider = FutureProvider.autoDispose<LibraryData>((
  ref,
) async {
  final user = ref.watch(authControllerProvider).valueOrNull?.user;
  if (user == null) throw StateError('Sign in to access My Library');
  final repository = ref.watch(readingProgressRepositoryProvider);
  final bookmarksFuture = repository.list(
    user.id,
    perPage: 100,
    bookmarked: true,
  );
  final historyFuture = repository.list(user.id, perPage: 100);
  final publicationsFuture = ref
      .watch(guidelinePublicationRepositoryProvider)
      .publications(perPage: 200);
  final library = ref.watch(guidelineLibraryRepositoryProvider);
  final collectionsFuture = library.collections(user.id);
  final downloadsFuture = library.downloads(user.id);
  await Future.wait<Object>([
    bookmarksFuture,
    historyFuture,
    publicationsFuture,
    collectionsFuture,
    downloadsFuture,
  ]);
  final bookmarks = (await bookmarksFuture).items;
  final history = (await historyFuture).items;
  final publications = (await publicationsFuture).items;
  final collections = await collectionsFuture;
  final downloads = await downloadsFuture;
  return LibraryData(
    bookmarks: bookmarks,
    history: history,
    publications: {for (final item in publications) item.id: item},
    collections: collections,
    downloads: downloads,
  );
});

class MyLibraryPage extends ConsumerWidget {
  const MyLibraryPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = SafeArea(
      child: ref
          .watch(libraryDataProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _LibraryError(
              message: error is StateError
                  ? 'Sign in to access bookmarks, reading history and offline content.'
                  : 'Your library could not be loaded.',
              onRetry: () => ref.invalidate(libraryDataProvider),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async => ref.refresh(libraryDataProvider.future),
              child: ListView(
                padding: AppSpacing.pagePadding,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'My Library',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Search library',
                        onPressed: () => context.push(AppRoutes.search),
                        icon: const Icon(LucideIcons.search),
                      ),
                      IconButton(
                        tooltip: 'Library options',
                        onPressed: () => _showLibraryOptions(context),
                        icon: const Icon(LucideIcons.listFilter),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  _LibrarySummary(
                    data: data,
                    onBookmarks: () => _showProgressItems(
                      context,
                      title: 'Bookmarks',
                      emptyMessage: 'Bookmark a guideline to find it here.',
                      items: data.bookmarks,
                      publications: data.publications,
                    ),
                    onHistory: () => _showProgressItems(
                      context,
                      title: 'Reading history',
                      emptyMessage: 'Guidelines you read will appear here.',
                      items: data.history,
                      publications: data.publications,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    return embedded ? body : Scaffold(body: body);
  }

  static Future<void> _showLibraryOptions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AppSpacing.gapMd,
              ListTile(
                leading: const Icon(LucideIcons.download),
                title: const Text('Manage offline content'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.offlineContent);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.messageCircle),
                title: const Text('AI Assistant history'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.chatList);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showProgressItems(
    BuildContext context, {
    required String title,
    required String emptyMessage,
    required List<ReadingProgress> items,
    required Map<String, GuidelinePublication> publications,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                AppSpacing.gapMd,
                Expanded(
                  child: items.isEmpty
                      ? _EmptyLibrarySection(message: emptyMessage)
                      : ListView(
                          children: [
                            for (final progress in items)
                              _ProgressTile(
                                progress: progress,
                                publication: publications[progress.guidelineId],
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibrarySummary extends StatelessWidget {
  const _LibrarySummary({
    required this.data,
    required this.onBookmarks,
    required this.onHistory,
  });
  final LibraryData data;
  final VoidCallback onBookmarks;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        _LibraryMenuTile(
          icon: LucideIcons.bookmark,
          label: 'Bookmarks',
          count: data.bookmarks.length,
          onTap: onBookmarks,
        ),
        const Divider(height: 1, indent: 64),
        _LibraryMenuTile(
          icon: LucideIcons.notebookPen,
          label: 'Notes',
          count: data.history
              .where((item) => item.notes.trim().isNotEmpty)
              .length,
        ),
        const Divider(height: 1, indent: 64),
        _LibraryMenuTile(
          icon: LucideIcons.download,
          label: 'Downloads',
          count: data.downloads.length,
          onTap: () => context.push(AppRoutes.offlineContent),
        ),
        const Divider(height: 1, indent: 64),
        _LibraryMenuTile(
          icon: LucideIcons.history,
          label: 'History',
          count: data.history.length,
          onTap: onHistory,
        ),
        const Divider(height: 1, indent: 64),
        _LibraryMenuTile(
          icon: LucideIcons.folder,
          label: 'Collections',
          count: data.collections.length,
        ),
        const Divider(height: 1, indent: 64),
        _LibraryMenuTile(
          icon: LucideIcons.refreshCw,
          label: 'Offline updates',
          count: data.history.where((item) => item.pendingSync).length,
          onTap: () => context.push(AppRoutes.offlineContent),
        ),
        const Divider(height: 1, indent: 64),
        _LibraryMenuTile(
          icon: LucideIcons.sparkles,
          label: 'AI Assistant history',
          onTap: () => context.push(AppRoutes.chatList),
        ),
      ],
    ),
  );
}

class _LibraryMenuTile extends StatelessWidget {
  const _LibraryMenuTile({
    required this.icon,
    required this.label,
    this.count,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: colors.primary, size: 19),
      ),
      title: Text(label),
      subtitle: count == null
          ? null
          : Text('$count ${count == 1 ? 'item' : 'items'}'),
      trailing: const Icon(LucideIcons.chevronRight, size: 19),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.progress, required this.publication});
  final ReadingProgress progress;
  final GuidelinePublication? publication;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const ClinicalIconTile(icon: LucideIcons.bookOpenText),
      title: Text(publication?.title ?? 'Saved guideline'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(progress.lastReadFormatted),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.progressPercentage.clamp(0, 1),
          ),
        ],
      ),
      trailing: progress.isBookmarked
          ? const Icon(LucideIcons.bookmarkCheck)
          : const Icon(LucideIcons.chevronRight),
      onTap: () =>
          context.push(AppRoutes.publicGuideline(progress.guidelineId)),
    ),
  );
}

class _EmptyLibrarySection extends StatelessWidget {
  const _EmptyLibrarySection({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(20), child: Text(message)),
  );
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.library, size: 44),
          AppSpacing.gapMd,
          Text(message, textAlign: TextAlign.center),
          AppSpacing.gapMd,
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

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
