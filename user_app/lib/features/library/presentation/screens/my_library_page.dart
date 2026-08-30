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

part '../widgets/my_library_page_library_header.dart';
part '../widgets/my_library_page_library_quick_stats.dart';
part '../widgets/my_library_page_library_stat.dart';
part '../widgets/my_library_page_library_summary.dart';
part '../widgets/my_library_page_library_menu_tile.dart';
part '../widgets/my_library_page_library_action_icon.dart';
part '../widgets/my_library_page_section_heading.dart';
part '../widgets/my_library_page_progress_tile.dart';
part '../widgets/my_library_page_empty_library_section.dart';
part '../widgets/my_library_page_library_loading.dart';
part '../widgets/my_library_page_library_error.dart';
part '../widgets/my_library_page_library_data.dart';

final libraryDataProvider = FutureProvider.autoDispose<LibraryData>((
  ref,
) async {
  final user = ref.watch(authControllerProvider).valueOrNull?.user;

  if (user == null) {
    throw StateError('Sign in to access My Library');
  }

  final progressRepository = ref.watch(readingProgressRepositoryProvider);

  final publicationRepository = ref.watch(
    guidelinePublicationRepositoryProvider,
  );

  final libraryRepository = ref.watch(guidelineLibraryRepositoryProvider);

  final bookmarksFuture = progressRepository.list(
    user.id,
    perPage: 100,
    bookmarked: true,
  );

  final historyFuture = progressRepository.list(user.id, perPage: 100);

  final publicationsFuture = publicationRepository.publications(perPage: 200);

  final collectionsFuture = libraryRepository.collections(user.id);

  final downloadsFuture = libraryRepository.downloads(user.id);

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
    publications: {
      for (final publication in publications) publication.id: publication,
    },
    collections: collections,
    downloads: downloads,
  );
});

class MyLibraryPage extends ConsumerWidget {
  const MyLibraryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryDataProvider);

    final body = SafeArea(
      child: library.when(
        loading: () => const _LibraryLoading(),
        error: (error, _) => _LibraryError(
          message: error is StateError
              ? 'Sign in to access bookmarks, notes, reading history, collections and offline content.'
              : 'Your library could not be loaded.',
          onRetry: () {
            ref.invalidate(libraryDataProvider);
          },
        ),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(libraryDataProvider);

              await ref.read(libraryDataProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePadding,
              children: [
                _LibraryHeader(
                  onSearch: () {
                    context.push(AppRoutes.search);
                  },
                  onOptions: () {
                    _showLibraryOptions(context);
                  },
                ),

                AppSpacing.gapLg,

                _LibraryQuickStats(
                  bookmarks: data.bookmarks.length,
                  downloads: data.downloads.length,
                  history: data.history.length,
                ),

                AppSpacing.gapLg,

                Text(
                  'Your library',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                AppSpacing.gapSm,

                _LibrarySummary(
                  data: data,

                  onBookmarks: () {
                    _showProgressItems(
                      context,
                      title: 'Bookmarks',
                      subtitle: 'Guidelines you have saved for quick access.',
                      emptyMessage: 'Bookmark a guideline to find it here.',
                      icon: LucideIcons.bookmark,
                      items: data.bookmarks,
                      publications: data.publications,
                    );
                  },

                  onNotes: () {
                    final items = data.history
                        .where((item) => item.notes.trim().isNotEmpty)
                        .toList(growable: false);

                    _showProgressItems(
                      context,
                      title: 'Reading notes',
                      subtitle: 'Private notes attached to your guidelines.',
                      emptyMessage:
                          'Notes you add while reading guidelines will appear here.',
                      icon: LucideIcons.notebookPen,
                      items: items,
                      publications: data.publications,
                      showNotes: true,
                    );
                  },

                  onDownloads: () {
                    context.push(AppRoutes.offlineContent);
                  },

                  onHistory: () {
                    _showProgressItems(
                      context,
                      title: 'Reading history',
                      subtitle: 'Continue recently viewed guidelines.',
                      emptyMessage: 'Guidelines you read will appear here.',
                      icon: LucideIcons.history,
                      items: data.history,
                      publications: data.publications,
                    );
                  },

                  onCollections: () {
                    _showCollections(context, data.collections);
                  },

                  onOfflineUpdates: () {
                    context.push(AppRoutes.offlineContent);
                  },

                  onAiHistory: () {
                    context.push(AppRoutes.chatList);
                  },
                ),

                AppSpacing.gapXl,

                if (data.history.isNotEmpty) ...[
                  _SectionHeading(
                    title: 'Continue reading',
                    actionLabel: 'View history',
                    onAction: () {
                      _showProgressItems(
                        context,
                        title: 'Reading history',
                        subtitle: 'Continue recently viewed guidelines.',
                        emptyMessage: 'Guidelines you read will appear here.',
                        icon: LucideIcons.history,
                        items: data.history,
                        publications: data.publications,
                      );
                    },
                  ),

                  AppSpacing.gapSm,

                  for (final progress in data.history.take(3))
                    _ProgressTile(
                      progress: progress,
                      publication: data.publications[progress.guidelineId],
                    ),
                ],

                AppSpacing.gapXl,
              ],
            ),
          );
        },
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(body: body);
  }

  static Future<void> _showLibraryOptions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Library options',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),

                AppSpacing.gapMd,

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LibraryActionIcon(icon: LucideIcons.download),
                  title: const Text('Manage offline content'),
                  subtitle: const Text(
                    'View downloaded guidelines and check for updates.',
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    context.push(AppRoutes.offlineContent);
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LibraryActionIcon(
                    icon: LucideIcons.messageCircle,
                  ),
                  title: const Text('AI Assistant history'),
                  subtitle: const Text(
                    'Return to previous clinical conversations.',
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    context.push(AppRoutes.chatList);
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LibraryActionIcon(icon: LucideIcons.search),
                  title: const Text('Search guidelines'),
                  subtitle: const Text(
                    'Find clinical guidance across MediGuide.',
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    context.push(AppRoutes.search);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showProgressItems(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emptyMessage,
    required IconData icon,
    required List<ReadingProgress> items,
    required Map<String, GuidelinePublication> publications,
    bool showNotes = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LibraryActionIcon(icon: icon),

                      AppSpacing.hGapMd,

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(
                                sheetContext,
                              ).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: Theme.of(sheetContext).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      sheetContext,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: items.isEmpty
                      ? _EmptyLibrarySection(icon: icon, message: emptyMessage)
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final progress = items[index];

                            return _ProgressTile(
                              progress: progress,
                              publication: publications[progress.guidelineId],
                              showNotes: showNotes,
                              onBeforeNavigate: () {
                                Navigator.of(sheetContext).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showCollections(
    BuildContext context,
    List<GuidelineCollectionSummary> collections,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const _LibraryActionIcon(icon: LucideIcons.folder),

                      AppSpacing.hGapMd,

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Collections',
                              style: Theme.of(
                                sheetContext,
                              ).textTheme.titleLarge,
                            ),
                            Text(
                              '${collections.length} '
                              '${collections.length == 1 ? 'collection' : 'collections'}',
                              style: Theme.of(sheetContext).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      sheetContext,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: collections.isEmpty
                      ? const _EmptyLibrarySection(
                          icon: LucideIcons.folderPlus,
                          message:
                              'Create collections to organize guidelines by topic, programme or clinical workflow.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: collections.length,
                          separatorBuilder: (_, _) {
                            return const Divider(height: 1, indent: 52);
                          },
                          itemBuilder: (context, index) {
                            final collection = collections[index];

                            //
                            // We intentionally do not assume fields such as
                            // collection.name / collection.id here because
                            // your GuidelineCollectionSummary model was not
                            // included in the snippet.
                            //
                            // The row is still interactive. Once you expose a
                            // collection-detail route, replace this handler
                            // with that route.
                            //
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const _LibraryActionIcon(
                                icon: LucideIcons.folder,
                              ),
                              title: Text('Collection ${index + 1}'),
                              subtitle: const Text('Open collection'),
                              trailing: const Icon(
                                LucideIcons.chevronRight,
                                size: 18,
                              ),
                              onTap: () {
                                _showCollectionDetails(
                                  sheetContext,
                                  index: index,
                                  collection: collection,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showCollectionDetails(
    BuildContext context, {
    required int index,
    required GuidelineCollectionSummary collection,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _LibraryActionIcon(icon: LucideIcons.folderOpen),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Text(
                        'Collection ${index + 1}',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),

                AppSpacing.gapMd,

                Text(
                  'Connect this action to your collection-detail route once '
                  'the fields and route for GuidelineCollectionSummary are available.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),

                AppSpacing.gapLg,

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(LucideIcons.arrowLeft),
                    label: const Text('Back to collections'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
