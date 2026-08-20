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

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.onSearch, required this.onOptions});

  final VoidCallback onSearch;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                'Saved guidelines, notes and reading activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Search library',
          onPressed: onSearch,
          icon: const Icon(LucideIcons.search),
        ),

        IconButton(
          tooltip: 'Library options',
          onPressed: onOptions,
          icon: const Icon(LucideIcons.ellipsis),
        ),
      ],
    );
  }
}

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

class _LibraryStat extends StatelessWidget {
  const _LibraryStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: colors.primary),

          const SizedBox(height: 6),

          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

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

class _LibraryMenuTile extends StatelessWidget {
  const _LibraryMenuTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final String description;
  final int? count;

  //
  // Required instead of optional.
  //
  // This intentionally prevents accidentally creating a library row
  // that looks tappable but does nothing.
  //
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      leading: _LibraryActionIcon(icon: icon),
      title: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),

          if (count != null)
            Container(
              constraints: const BoxConstraints(minWidth: 26),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 19),
    );
  }
}

class _LibraryActionIcon extends StatelessWidget {
  const _LibraryActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: colors.primary, size: 19),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.progress,
    required this.publication,
    this.showNotes = false,
    this.onBeforeNavigate,
  });

  final ReadingProgress progress;
  final GuidelinePublication? publication;
  final bool showNotes;
  final VoidCallback? onBeforeNavigate;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.progressPercentage.clamp(0.0, 1.0);

    final progressPercent = (progressValue * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          onBeforeNavigate?.call();

          _openProgress(context, progress);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClinicalIconTile(icon: LucideIcons.bookOpenText),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication?.title ?? 'Saved guideline',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),

                    AppSpacing.gapSm,

                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          '$progressPercent%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock3,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            progress.lastReadFormatted,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),

                        if (progress.isBookmarked)
                          const Icon(LucideIcons.bookmarkCheck, size: 17),
                      ],
                    ),

                    if (showNotes && progress.notes.trim().isNotEmpty) ...[
                      AppSpacing.gapSm,

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.notebookPen, size: 16),

                            AppSpacing.hGapSm,

                            Expanded(
                              child: Text(
                                progress.notes,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              AppSpacing.hGapSm,

              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(LucideIcons.chevronRight, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProgress(BuildContext context, ReadingProgress progress) {
    //
    // Resume directly in the reader instead of returning to
    // the guideline overview.
    //
    var location = AppRoutes.readPublicGuideline(progress.guidelineId);

    //
    // If there is a saved section, use the reader's deep-link handling
    // that we added to PublicationGuidelinePage.
    //
    final currentSection = progress.currentSection.trim();

    if (currentSection.isNotEmpty) {
      location =
          '$location'
          '?section=${Uri.encodeQueryComponent(currentSection)}';
    }

    context.push(location);
  }
}

class _EmptyLibrarySection extends StatelessWidget {
  const _EmptyLibrarySection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 42,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),

              AppSpacing.gapMd,

              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryLoading extends StatelessWidget {
  const _LibraryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.library, size: 44),

            AppSpacing.gapMd,

            Text(message, textAlign: TextAlign.center),

            AppSpacing.gapMd,

            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
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
