import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/app_status_badge.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/presentation/controllers/publication_guideline_controller.dart';
import 'package:user_app/features/guidelines/presentation/widgets/publication_block_view.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/downloads/presentation/controllers/guideline_downloads_controller.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';

class PublicationGuidelinePage extends ConsumerStatefulWidget {
  const PublicationGuidelinePage({
    super.key,
    required this.guidelineId,
    this.readerOnly = false,
  });
  final String guidelineId;
  final bool readerOnly;

  @override
  ConsumerState<PublicationGuidelinePage> createState() =>
      _PublicationGuidelinePageState();
}

class _PublicationGuidelinePageState
    extends ConsumerState<PublicationGuidelinePage> {
  String? _selectedSectionId;
  String? _currentSectionId;
  final Map<String, GlobalKey> _sectionKeys = {};
  final ScrollController _readerScrollController = ScrollController();
  bool _deepLinkApplied = false;
  bool _initialProgressScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_deepLinkApplied) return;
    _deepLinkApplied = true;
    final section = GoRouterState.of(context).uri.queryParameters['section'];
    if (section != null && section.trim().isNotEmpty) {
      _selectedSectionId = section.trim();
    }
  }

  @override
  void dispose() {
    _readerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(publicationGuidelineProvider(widget.guidelineId));
    final progress = ref
        .watch(publicationReadingProgressProvider(widget.guidelineId))
        .valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          content.valueOrNull?.publication.title ??
              (widget.readerOnly ? 'Guideline reader' : 'Guideline overview'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: progress?.isBookmarked == true
                ? 'Remove bookmark'
                : 'Bookmark guideline',
            onPressed: () => _toggleBookmark(context),
            icon: Icon(
              progress?.isBookmarked == true
                  ? LucideIcons.bookmarkCheck
                  : LucideIcons.bookmark,
            ),
          ),
          PopupMenuButton<_GuidelineMenuAction>(
            tooltip: 'More guideline actions',
            onSelected: (action) => _handleMenuAction(
              context,
              action,
              content.valueOrNull,
              progress?.notes ?? '',
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _GuidelineMenuAction.search,
                child: ListTile(
                  leading: Icon(LucideIcons.search),
                  title: Text('Search guideline'),
                ),
              ),
              PopupMenuItem(
                value: _GuidelineMenuAction.notes,
                child: ListTile(
                  leading: Icon(LucideIcons.notebookPen),
                  title: Text('Reading notes'),
                ),
              ),
              PopupMenuItem(
                value: _GuidelineMenuAction.share,
                child: ListTile(
                  leading: Icon(LucideIcons.share2),
                  title: Text('Copy link'),
                ),
              ),
              PopupMenuItem(
                value: _GuidelineMenuAction.original,
                child: ListTile(
                  leading: Icon(LucideIcons.fileText),
                  title: Text('Open original document'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: content.when(
        loading: () => const AppLoadingView(message: 'Loading guideline...'),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () =>
              ref.invalidate(publicationGuidelineProvider(widget.guidelineId)),
        ),
        data: (value) => widget.readerOnly
            ? _content(context, value)
            : _overviewPage(context, value, progress?.isBookmarked == true),
      ),
      bottomNavigationBar: content.valueOrNull == null
          ? null
          : _ReaderActionBar(
              isBookmarked: progress?.isBookmarked == true,
              showRead: !widget.readerOnly,
              onRead: () => context.push(
                AppRoutes.readPublicGuideline(widget.guidelineId),
              ),
              onBookmark: () => _toggleBookmark(context),
              onNotes: () => _editNotes(context, progress?.notes ?? ''),
              onShare: () => _copyLink(context),
              onOriginal: () => _openOriginal(context),
              onDownload: () => _download(context, content.requireValue),
            ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _GuidelineMenuAction action,
    GuidelinePublicationContent? content,
    String notes,
  ) async {
    switch (action) {
      case _GuidelineMenuAction.search:
        if (content != null) await _searchWithin(context, content);
      case _GuidelineMenuAction.notes:
        await _editNotes(context, notes);
      case _GuidelineMenuAction.share:
        await _copyLink(context);
      case _GuidelineMenuAction.original:
        await _openOriginal(context);
    }
  }

  Widget _overviewPage(
    BuildContext context,
    GuidelinePublicationContent value,
    bool isBookmarked,
  ) => _GuidelineOverview(
    content: value,
    isBookmarked: isBookmarked,
    onRead: () =>
        context.push(AppRoutes.readPublicGuideline(widget.guidelineId)),
    onSection: (sectionId) => context.push(
      '${AppRoutes.readPublicGuideline(widget.guidelineId)}?section=${Uri.encodeQueryComponent(sectionId)}',
    ),
    onOriginal: () => _openOriginal(context),
  );

  Future<void> _download(
    BuildContext context,
    GuidelinePublicationContent content,
  ) async {
    final original =
        !content.manifest.hasOfflinePackage && content.manifest.hasOriginalPdf;
    if (!content.manifest.hasOfflinePackage &&
        !content.manifest.hasOriginalPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This guideline has no downloadable asset.'),
        ),
      );
      return;
    }
    try {
      final result = await ref
          .read(guidelineDownloadsControllerProvider.notifier)
          .download(content, originalDocument: original);
      if (!context.mounted) return;
      final message = result.status == OfflineDownloadStatus.ready
          ? 'Verified offline copy is ready.'
          : 'Download ${result.status.name}.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    }
  }

  Widget _content(BuildContext context, GuidelinePublicationContent value) {
    final mode = value.manifest.recommendedMode;
    if (mode == GuidelineReaderMode.originalDocument) {
      final asset = ref
          .watch(guidelineOriginalDocumentProvider(widget.guidelineId))
          .valueOrNull;
      return _OriginalDocumentReader(
        publication: value.publication,
        manifest: value.manifest,
        asset: asset,
        onOpen: () => _openOriginal(context),
      );
    }
    final sections = value.sections;
    _scheduleInitialProgress(sections);
    final selected = _selectedSectionId;
    final selectedIds = selected == null
        ? <String>{}
        : _sectionAndDescendants(sections, selected);
    final visibleSections =
        mode == GuidelineReaderMode.structured && selected != null
        ? sections.where((section) => selectedIds.contains(section.id)).toList()
        : sections;
    final rootSections = sections
        .where(
          (section) => section.parentId == null || section.parentId!.isEmpty,
        )
        .toList(growable: false);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _trackVisibleSection(sections),
          );
        }
        return false;
      },
      child: CustomScrollView(
        controller: _readerScrollController,
        slivers: [
          SliverToBoxAdapter(child: _Overview(content: value)),
          if (_currentSectionId != null)
            SliverToBoxAdapter(
              child: Semantics(
                liveRegion: true,
                label:
                    'Current section ${sections.where((item) => item.id == _currentSectionId).map((item) => item.title).firstOrNull ?? ''}',
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.horizontalPadding(context),
                  ),
                  child: Text(
                    'Current section: ${sections.where((item) => item.id == _currentSectionId).map((item) => item.title).firstOrNull ?? ''}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),
          if (sections.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SectionHeaderDelegate(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Semantics(
                    label: 'Guideline chapters',
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.horizontalPadding(context),
                        vertical: AppSpacing.sm,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: rootSections.length,
                      separatorBuilder: (_, _) => AppSpacing.gapSm,
                      itemBuilder: (_, index) {
                        final section = rootSections[index];
                        return ChoiceChip(
                          label: Text(section.title),
                          selected: selected == section.id,
                          onSelected: (_) {
                            final next = selected == section.id
                                ? null
                                : section.id;
                            setState(() => _selectedSectionId = next);
                            if (next != null) {
                              unawaited(_recordSectionProgress(sections, next));
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              AppSpacing.md,
              Responsive.horizontalPadding(context),
              AppSpacing.xxxl,
            ),
            sliver: SliverList.builder(
              itemCount: visibleSections.length,
              itemBuilder: (_, index) {
                final section = visibleSections[index];
                final blocks = value.blocksFor(section.id);
                _sectionKeys.putIfAbsent(section.id, GlobalKey.new);
                return Semantics(
                  key: _sectionKeys[section.id],
                  container: true,
                  label: section.title,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            section.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (section.pageLabel.isNotEmpty)
                          Text(
                            section.pageLabel,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        AppSpacing.gapMd,
                        if (blocks.isEmpty)
                          const Text('No reviewed content is available here.')
                        else
                          for (final block in blocks) ...[
                            PublicationBlockView(
                              block: block,
                              guidelineId: widget.guidelineId,
                            ),
                            AppSpacing.gapLg,
                          ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleInitialProgress(List<PublicationSection> sections) {
    if (_initialProgressScheduled || sections.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) return;

    final requested = _selectedSectionId;
    final sectionId =
        requested != null && sections.any((section) => section.id == requested)
        ? requested
        : sections.first.id;
    _initialProgressScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_recordSectionProgress(sections, sectionId));
    });
  }

  void _trackVisibleSection(List<PublicationSection> sections) {
    if (!mounted || sections.isEmpty) return;
    String? nearest;
    var distance = double.infinity;
    for (final section in sections) {
      final target = _sectionKeys[section.id]?.currentContext;
      final box = target?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      final candidate = (dy - 120).abs();
      if (candidate < distance) {
        distance = candidate;
        nearest = section.id;
      }
    }
    if (nearest == null || nearest == _currentSectionId) return;
    setState(() => _currentSectionId = nearest);
    unawaited(_recordSectionProgress(sections, nearest));
  }

  Set<String> _sectionAndDescendants(
    List<PublicationSection> sections,
    String root,
  ) {
    final result = <String>{root};
    var frontier = <String>{root};
    while (frontier.isNotEmpty) {
      final next = sections
          .where(
            (section) =>
                section.parentId != null && frontier.contains(section.parentId),
          )
          .map((section) => section.id)
          .where(result.add)
          .toSet();
      frontier = next;
    }
    return result;
  }

  Future<void> _recordSectionProgress(
    List<PublicationSection> sections,
    String sectionId,
  ) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null || sections.isEmpty) return;
    final index = sections.indexWhere((section) => section.id == sectionId);
    final progress = index < 0 ? 0.0 : (index + 1) / sections.length;
    await ref
        .read(readingProgressRepositoryProvider)
        .upsert(user.id, widget.guidelineId, {
          'current_section': sectionId,
          'total_sections': sections.length,
          'progress_percentage': progress.clamp(0.0, 1.0),
          'last_read_at': DateTime.now().toUtc().toIso8601String(),
        });
    ref.invalidate(publicationReadingProgressProvider(widget.guidelineId));
  }

  Future<void> _openOriginal(BuildContext context) async {
    try {
      final asset = await ref.read(
        guidelineOriginalDocumentProvider(widget.guidelineId).future,
      );
      if (!context.mounted) return;
      if (asset == null || asset.url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Original document is unavailable.')),
        );
        return;
      }
      context.push(
        AppRoutes.documentReader,
        extra: DocumentReaderArgs(
          title: asset.originalFilename.isEmpty
              ? 'Original guideline'
              : asset.originalFilename,
          source: asset.url,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open original document: $error')),
      );
    }
  }

  Future<void> _toggleBookmark(BuildContext context) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) {
      _requireSignIn(context, 'Sign in to save bookmarks and sync them.');
      return;
    }
    final provider = publicationReadingProgressProvider(widget.guidelineId);
    final current = ref.read(provider).valueOrNull;
    await ref.read(readingProgressRepositoryProvider).upsert(
      user.id,
      widget.guidelineId,
      {'is_bookmarked': !(current?.isBookmarked ?? false)},
    );
    ref.invalidate(provider);
  }

  Future<void> _editNotes(BuildContext context, String current) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) {
      _requireSignIn(context, 'Sign in to create private reading notes.');
      return;
    }
    final controller = TextEditingController(text: current);
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reading notes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AppSpacing.gapMd,
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 8,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Add a private note about this guideline',
                ),
              ),
              AppSpacing.gapMd,
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, controller.text),
                child: const Text('Save note'),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (note == null) return;
    await ref.read(readingProgressRepositoryProvider).upsert(
      user.id,
      widget.guidelineId,
      {'notes': note.trim()},
    );
    ref.invalidate(publicationReadingProgressProvider(widget.guidelineId));
  }

  Future<void> _copyLink(BuildContext context) async {
    final link = AppRoutes.publicGuideline(widget.guidelineId);
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Guideline link copied.')));
  }

  void _requireSignIn(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    final destination = Uri.encodeComponent(
      AppRoutes.publicGuideline(widget.guidelineId),
    );
    context.push('${AppRoutes.login}?redirect=$destination');
  }

  Future<void> _searchWithin(
    BuildContext context,
    GuidelinePublicationContent content,
  ) async {
    final sectionId = await showSearch<String?>(
      context: context,
      delegate: _GuidelineContentSearchDelegate(content),
    );
    if (!mounted || sectionId == null) return;
    setState(() => _selectedSectionId = sectionId);
    if (content.manifest.recommendedMode == GuidelineReaderMode.partial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _sectionKeys[sectionId]?.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 300),
            alignment: 0.1,
          );
        }
      });
    }
  }
}

enum _GuidelineMenuAction { search, notes, share, original }

class _GuidelineContentSearchDelegate extends SearchDelegate<String?> {
  _GuidelineContentSearchDelegate(this.content);
  final GuidelinePublicationContent content;

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear search',
        onPressed: () => query = '',
        icon: const Icon(LucideIcons.x),
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Close search',
    onPressed: () => close(context, null),
    icon: const Icon(LucideIcons.arrowLeft),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return const Center(
        child: Text('Search this guideline’s reviewed text.'),
      );
    }
    final matches = <({PublicationSection section, String snippet})>[];
    for (final section in content.sections) {
      for (final block in content.blocksFor(section.id)) {
        final text = _searchableBlockText(block);
        if (section.title.toLowerCase().contains(needle) ||
            text.toLowerCase().contains(needle)) {
          matches.add((section: section, snippet: text));
          break;
        }
      }
    }
    if (matches.isEmpty) {
      return const Center(child: Text('No matching reviewed content.'));
    }
    return ListView.separated(
      itemCount: matches.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final match = matches[index];
        return ListTile(
          title: Text(match.section.title),
          subtitle: Text(
            match.snippet,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: match.section.pageLabel.isEmpty
              ? null
              : Text(match.section.pageLabel),
          onTap: () => close(context, match.section.id),
        );
      },
    );
  }
}

String _searchableBlockText(GuidelineBlock block) => switch (block) {
  ParagraphGuidelineBlock(:final text) => text,
  HeadingGuidelineBlock(:final text) => text,
  OrderedListGuidelineBlock(:final items) => items.join(' '),
  UnorderedListGuidelineBlock(:final items) => items.join(' '),
  TableGuidelineBlock(:final payload) => [
    payload.title,
    ...payload.columns,
    ...payload.rows.expand((row) => row),
  ].join(' '),
  FigureGuidelineBlock(:final payload) =>
    '${payload.caption} ${payload.alternativeText}',
  CalloutGuidelineBlock(:final payload) =>
    '${payload.title} ${payload.content}',
  AlgorithmGuidelineBlock(:final payload) => [
    payload.title,
    ...payload.nodes.map((node) => node.label),
  ].join(' '),
  ReferenceGuidelineBlock(:final citation) => citation,
  PageBreakGuidelineBlock(:final page) => 'Page $page',
  UnknownGuidelineBlock() => '',
};

class _GuidelineOverview extends StatelessWidget {
  const _GuidelineOverview({
    required this.content,
    required this.isBookmarked,
    required this.onRead,
    required this.onSection,
    required this.onOriginal,
  });

  final GuidelinePublicationContent content;
  final bool isBookmarked;
  final VoidCallback onRead;
  final ValueChanged<String> onSection;
  final VoidCallback onOriginal;

  @override
  Widget build(BuildContext context) {
    final publication = content.publication;
    final manifest = content.manifest;
    final keyRecommendations = content.blocks
        .whereType<CalloutGuidelineBlock>()
        .where(
          (block) => const {
            'key_point',
            'recommendation',
            'important',
          }.contains(block.blockType),
        )
        .take(6)
        .toList(growable: false);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        AppSpacing.lg,
        Responsive.horizontalPadding(context),
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          publication.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (publication.description.isNotEmpty) ...[
          AppSpacing.gapSm,
          Text(publication.description),
        ],
        AppSpacing.gapMd,
        _ReviewStatus(manifest: manifest),
        AppSpacing.gapLg,
        _MetadataGrid(publication: publication),
        AppSpacing.gapLg,
        Text(
          'Available content',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        AppSpacing.gapSm,
        _CapabilityWrap(manifest: manifest),
        if (keyRecommendations.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text(
            'Key recommendations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapSm,
          for (final block in keyRecommendations)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(LucideIcons.circleCheck),
                title: Text(
                  block.payload.title.isEmpty
                      ? 'Recommendation'
                      : block.payload.title,
                ),
                subtitle: Text(block.payload.content),
              ),
            ),
        ],
        if (content.sections.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text('Chapters', style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.gapSm,
          for (final section in content.sections)
            Padding(
              padding: EdgeInsets.only(
                left: ((section.level - 1).clamp(0, 5)) * 16.0,
              ),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  section.level <= 1
                      ? LucideIcons.bookOpen
                      : LucideIcons.cornerDownRight,
                  size: 18,
                ),
                title: Text(section.title),
                subtitle: section.pageLabel.isEmpty
                    ? null
                    : Text(section.pageLabel),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () => onSection(section.id),
              ),
            ),
        ],
        AppSpacing.gapLg,
        FilledButton.icon(
          onPressed: onRead,
          icon: const Icon(LucideIcons.bookOpenText),
          label: const Text('Read guideline'),
        ),
        if (manifest.hasOriginalPdf) ...[
          AppSpacing.gapSm,
          OutlinedButton.icon(
            onPressed: onOriginal,
            icon: const Icon(LucideIcons.fileText),
            label: const Text('Open original document'),
          ),
        ],
      ],
    );
  }
}

class _MetadataGrid extends StatelessWidget {
  const _MetadataGrid({required this.publication});
  final GuidelinePublication publication;

  @override
  Widget build(BuildContext context) {
    final values = <(String, String, IconData)>[
      ('Source', publication.sourceOrganization, LucideIcons.landmark),
      ('Version', publication.version, LucideIcons.gitBranch),
      ('Published', publication.publicationDate, LucideIcons.calendar),
      ('Review date', publication.reviewDate, LucideIcons.calendarCheck),
      ('Population', publication.intendedPopulation, LucideIcons.users),
      ('Care level', publication.healthcareLevel, LucideIcons.hospital),
      ('Language', publication.language, LucideIcons.languages),
      ('Program area', publication.programArea, LucideIcons.tags),
    ].where((item) => item.$2.trim().isNotEmpty).toList(growable: false);
    if (values.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in values)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 280),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                dense: true,
                leading: Icon(item.$3, size: 20),
                title: Text(item.$1),
                subtitle: Text(item.$2),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus({required this.manifest});
  final GuidelineManifest manifest;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (manifest.recommendedMode) {
      GuidelineReaderMode.structured => (
        'Reviewed structured content',
        AppStatusTone.success,
        LucideIcons.badgeCheck,
      ),
      GuidelineReaderMode.partial => (
        'Partially structured; verify source pages',
        AppStatusTone.warning,
        LucideIcons.fileWarning,
      ),
      GuidelineReaderMode.originalDocument => (
        'Original document is the clinical source',
        AppStatusTone.neutral,
        LucideIcons.fileText,
      ),
    };
    return AppStatusBadge(icon: icon, tone: tone, label: label);
  }
}

class _CapabilityWrap extends StatelessWidget {
  const _CapabilityWrap({required this.manifest});
  final GuidelineManifest manifest;

  @override
  Widget build(BuildContext context) {
    final values = <(bool, String, IconData)>[
      (manifest.hasChapters, 'Chapters', LucideIcons.listTree),
      (manifest.hasKeyPoints, 'Key points', LucideIcons.circleCheck),
      (manifest.hasTables, 'Tables', LucideIcons.table2),
      (manifest.hasFigures, 'Figures', LucideIcons.image),
      (manifest.hasAlgorithms, 'Algorithms', LucideIcons.workflow),
      (manifest.hasOriginalPdf, 'Original PDF', LucideIcons.fileText),
      (
        manifest.hasOfflinePackage,
        'Offline package',
        LucideIcons.cloudDownload,
      ),
    ].where((item) => item.$1).toList(growable: false);
    if (values.isEmpty) return const Text('Original document only');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          Chip(avatar: Icon(value.$3, size: 18), label: Text(value.$2)),
      ],
    );
  }
}

class _ReaderActionBar extends StatelessWidget {
  const _ReaderActionBar({
    required this.isBookmarked,
    required this.showRead,
    required this.onRead,
    required this.onBookmark,
    required this.onNotes,
    required this.onShare,
    required this.onOriginal,
    required this.onDownload,
  });
  final bool isBookmarked;
  final bool showRead;
  final VoidCallback onRead;
  final VoidCallback onBookmark;
  final VoidCallback onNotes;
  final VoidCallback onShare;
  final VoidCallback onOriginal;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showRead)
                _Action(
                  icon: LucideIcons.bookOpenText,
                  label: 'Read',
                  onTap: onRead,
                ),
              _Action(
                icon: isBookmarked
                    ? LucideIcons.bookmarkCheck
                    : LucideIcons.bookmark,
                label: 'Bookmark',
                onTap: onBookmark,
              ),
              _Action(
                icon: LucideIcons.notebookPen,
                label: 'Notes',
                onTap: onNotes,
              ),
              _Action(icon: LucideIcons.share2, label: 'Share', onTap: onShare),
              _Action(
                icon: LucideIcons.fileText,
                label: 'Original',
                onTap: onOriginal,
              ),
              _Action(
                icon: LucideIcons.download,
                label: 'Offline',
                onTap: onDownload,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: largeText ? 88 : 64,
          height: largeText ? 88 : 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.content});
  final GuidelinePublicationContent content;

  @override
  Widget build(BuildContext context) {
    final publication = content.publication;
    final manifest = content.manifest;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        AppSpacing.lg,
        Responsive.horizontalPadding(context),
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            publication.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (publication.description.isNotEmpty) ...[
            AppSpacing.gapSm,
            Text(publication.description),
          ],
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (publication.sourceOrganization.isNotEmpty)
                Chip(label: Text(publication.sourceOrganization)),
              if (publication.version.isNotEmpty)
                Chip(label: Text('Version ${publication.version}')),
              AppStatusBadge(
                icon: manifest.recommendedMode == GuidelineReaderMode.structured
                    ? LucideIcons.badgeCheck
                    : LucideIcons.fileWarning,
                tone: manifest.recommendedMode == GuidelineReaderMode.structured
                    ? AppStatusTone.success
                    : AppStatusTone.warning,
                label:
                    manifest.recommendedMode == GuidelineReaderMode.structured
                    ? 'Reviewed structured content'
                    : 'Partial reviewed content',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OriginalDocumentReader extends StatelessWidget {
  const _OriginalDocumentReader({
    required this.publication,
    required this.manifest,
    required this.asset,
    required this.onOpen,
  });
  final GuidelinePublication publication;
  final GuidelineManifest manifest;
  final GuidelineAsset? asset;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            const Icon(LucideIcons.fileText, size: 64),
            AppSpacing.gapMd,
            Text(
              publication.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.gapSm,
            const Text(
              'Reviewed structured extraction is not available. Use the original document as the clinical source.',
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapLg,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (manifest.version.isNotEmpty)
                  Chip(label: Text('Version ${manifest.version}')),
                Chip(
                  avatar: Icon(
                    manifest.hasOfflinePackage
                        ? LucideIcons.cloudDownload
                        : LucideIcons.cloudOff,
                    size: 18,
                  ),
                  label: Text(
                    manifest.hasOfflinePackage
                        ? 'Offline package available'
                        : 'Online source only',
                  ),
                ),
                if (asset?.sizeBytes != 0)
                  Chip(label: Text(_fileSize(asset?.sizeBytes ?? 0))),
                if (asset?.checksum.isNotEmpty == true)
                  const Chip(
                    avatar: Icon(LucideIcons.shieldCheck, size: 18),
                    label: Text('Checksum supplied'),
                  ),
              ],
            ),
            AppSpacing.gapLg,
            FilledButton.icon(
              onPressed: manifest.hasOriginalPdf ? onOpen : null,
              icon: const Icon(LucideIcons.externalLink),
              label: Text(
                manifest.hasOriginalPdf
                    ? 'Open original document'
                    : 'Original unavailable',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SectionHeaderDelegate({required this.child});
  final Widget child;
  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
