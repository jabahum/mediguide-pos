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

final _libraryProvider = FutureProvider.autoDispose<_LibraryData>((ref) async {
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
  return _LibraryData(
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
          .watch(_libraryProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _LibraryError(
              message: error is StateError
                  ? 'Sign in to access bookmarks, reading history and offline content.'
                  : 'Your library could not be loaded.',
              onRetry: () => ref.invalidate(_libraryProvider),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async => ref.refresh(_libraryProvider.future),
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
                    ],
                  ),
                  AppSpacing.gapMd,
                  _LibrarySummary(data: data),
                  AppSpacing.gapLg,
                  Text(
                    'Bookmarks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  AppSpacing.gapSm,
                  if (data.bookmarks.isEmpty)
                    const _EmptyLibrarySection(
                      message: 'Bookmark a guideline to find it here.',
                    )
                  else
                    for (final progress in data.bookmarks.take(6))
                      _ProgressTile(
                        progress: progress,
                        publication: data.publications[progress.guidelineId],
                      ),
                  AppSpacing.gapLg,
                  Text(
                    'Reading history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  AppSpacing.gapSm,
                  if (data.history.isEmpty)
                    const _EmptyLibrarySection(
                      message: 'Guidelines you read will appear here.',
                    )
                  else
                    for (final progress in data.history.take(12))
                      _ProgressTile(
                        progress: progress,
                        publication: data.publications[progress.guidelineId],
                      ),
                ],
              ),
            ),
          ),
    );
    return embedded ? body : Scaffold(body: body);
  }
}

class _LibrarySummary extends StatelessWidget {
  const _LibrarySummary({required this.data});
  final _LibraryData data;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 2.2,
    children: [
      _SummaryCard(
        icon: LucideIcons.bookmark,
        label: 'Bookmarks',
        count: data.bookmarks.length,
      ),
      _SummaryCard(
        icon: LucideIcons.history,
        label: 'History',
        count: data.history.length,
      ),
      _SummaryCard(
        icon: LucideIcons.notebookPen,
        label: 'Notes',
        count: data.history
            .where((item) => item.notes.trim().isNotEmpty)
            .length,
      ),
      _SummaryCard(
        icon: LucideIcons.download,
        label: 'Downloads',
        count: data.downloads.length,
      ),
      _SummaryCard(
        icon: LucideIcons.folder,
        label: 'Collections',
        count: data.collections.length,
      ),
      _SummaryCard(
        icon: LucideIcons.refreshCw,
        label: 'Pending sync',
        count: data.history.where((item) => item.pendingSync).length,
      ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text('$label\n$count', maxLines: 2)),
        ],
      ),
    ),
  );
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.progress, required this.publication});
  final ReadingProgress progress;
  final GuidelinePublication? publication;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const CircleAvatar(
        child: Icon(LucideIcons.bookOpenText, size: 20),
      ),
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

class _LibraryData {
  const _LibraryData({
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
