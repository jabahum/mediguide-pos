import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/app_status_badge.dart';
import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/downloads/presentation/controllers/guideline_downloads_controller.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/presentation/controllers/publication_guideline_controller.dart';
import 'package:user_app/features/guidelines/presentation/widgets/publication_block_view.dart';

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
  final ScrollController _readerScrollController = ScrollController();

  final Map<String, GlobalKey> _sectionKeys = {};

  String? _selectedSectionId;
  String? _currentSectionId;

  Timer? _progressDebounce;

  bool _deepLinkApplied = false;
  bool _initialProgressScheduled = false;
  bool _initialSectionScrollScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_deepLinkApplied) return;

    _deepLinkApplied = true;

    final section = GoRouterState.of(
      context,
    ).uri.queryParameters['section']?.trim();

    if (section != null && section.isNotEmpty) {
      _selectedSectionId = section;
    }
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _readerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(publicationGuidelineProvider(widget.guidelineId));

    final progress = ref
        .watch(publicationReadingProgressProvider(widget.guidelineId))
        .valueOrNull;

    final loadedContent = content.valueOrNull;

    return Scaffold(
      appBar: _buildAppBar(
        context,
        content: loadedContent,
        isBookmarked: progress?.isBookmarked == true,
        notes: progress?.notes ?? '',
      ),
      body: content.when(
        loading: () => const AppLoadingView(message: 'Loading guideline...'),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(publicationGuidelineProvider(widget.guidelineId));
          },
        ),
        data: (value) {
          if (widget.readerOnly) {
            return _readerPage(context, value);
          }

          return _overviewPage(context, value, progress?.isBookmarked == true);
        },
      ),
      bottomNavigationBar: loadedContent == null
          ? null
          : widget.readerOnly
          ? _ReaderActionBar(
              isBookmarked: progress?.isBookmarked == true,
              onContents: () => _showContents(context, loadedContent),
              onAskAi: () => _openAiAssistant(context, loadedContent),
              onBookmark: () => _toggleBookmark(context),
              onMore: () => _showMoreActions(
                context,
                loadedContent,
                progress?.notes ?? '',
              ),
            )
          : _OverviewActionBar(
              onRead: () => _openReader(context),
              onDownload: () => _download(context, loadedContent),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required GuidelinePublicationContent? content,
    required bool isBookmarked,
    required String notes,
  }) {
    return AppBar(
      title: Text(
        content?.publication.title ??
            (widget.readerOnly ? 'Guideline reader' : 'Guideline overview'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (widget.readerOnly && content != null)
          IconButton(
            tooltip: 'Search guideline',
            onPressed: () => _searchWithin(context, content),
            icon: const Icon(LucideIcons.search),
          ),
        IconButton(
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark guideline',
          onPressed: () => _toggleBookmark(context),
          icon: Icon(
            isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
          ),
        ),
        if (content != null)
          PopupMenuButton<_GuidelineMenuAction>(
            tooltip: 'More guideline actions',
            onSelected: (action) =>
                _handleMenuAction(context, action, content, notes),
            itemBuilder: (_) => [
              if (!widget.readerOnly)
                const PopupMenuItem(
                  value: _GuidelineMenuAction.search,
                  child: ListTile(
                    leading: Icon(LucideIcons.search),
                    title: Text('Search guideline'),
                  ),
                ),
              const PopupMenuItem(
                value: _GuidelineMenuAction.notes,
                child: ListTile(
                  leading: Icon(LucideIcons.notebookPen),
                  title: Text('Reading notes'),
                ),
              ),
              const PopupMenuItem(
                value: _GuidelineMenuAction.share,
                child: ListTile(
                  leading: Icon(LucideIcons.share2),
                  title: Text('Copy link'),
                ),
              ),
              const PopupMenuItem(
                value: _GuidelineMenuAction.original,
                child: ListTile(
                  leading: Icon(LucideIcons.fileText),
                  title: Text('Open original document'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _overviewPage(
    BuildContext context,
    GuidelinePublicationContent value,
    bool isBookmarked,
  ) {
    return _GuidelineOverview(
      content: value,
      isBookmarked: isBookmarked,
      onRead: () => _openReader(context),
      onSection: (sectionId) {
        context.push(
          '${AppRoutes.readPublicGuideline(widget.guidelineId)}'
          '?section=${Uri.encodeQueryComponent(sectionId)}',
        );
      },
      onOriginal: () => _openOriginal(context),
      onDownload: () => _download(context, value),
      onBookmark: () => _toggleBookmark(context),
    );
  }

  Widget _readerPage(BuildContext context, GuidelinePublicationContent value) {
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
    _scheduleInitialSectionScroll(sections);

    final currentSection = _findSection(
      sections,
      _currentSectionId ?? _selectedSectionId,
    );

    final currentSectionIndex = currentSection == null
        ? -1
        : sections.indexWhere((section) => section.id == currentSection.id);

    final readerProgress = sections.isEmpty
        ? 0.0
        : currentSectionIndex < 0
        ? 0.0
        : ((currentSectionIndex + 1) / sections.length).clamp(0.0, 1.0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _trackVisibleSection(sections);
          });
        }

        return false;
      },
      child: CustomScrollView(
        controller: _readerScrollController,
        slivers: [
          SliverToBoxAdapter(child: _ReaderOverview(content: value)),

          if (sections.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _ReaderHeaderDelegate(
                child: _ReaderProgressHeader(
                  currentSection: currentSection,
                  currentIndex: currentSectionIndex,
                  totalSections: sections.length,
                  progress: readerProgress,
                  onContents: () => _showContents(context, value),
                ),
              ),
            ),

          if (sections.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Text(
                    'No reviewed structured sections are available.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                AppSpacing.lg,
                Responsive.horizontalPadding(context),
                AppSpacing.xxxl,
              ),
              sliver: SliverList.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];

                  final key = _sectionKeys.putIfAbsent(
                    section.id,
                    GlobalKey.new,
                  );

                  final blocks = value.blocksFor(section.id);

                  return Semantics(
                    key: key,
                    container: true,
                    label: section.title,
                    child: _GuidelineReaderSection(
                      guidelineId: widget.guidelineId,
                      section: section,
                      blocks: blocks,
                      isCurrent: section.id == _currentSectionId,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openReader(BuildContext context) {
    context.push(AppRoutes.readPublicGuideline(widget.guidelineId));
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _GuidelineMenuAction action,
    GuidelinePublicationContent content,
    String notes,
  ) async {
    switch (action) {
      case _GuidelineMenuAction.search:
        await _searchWithin(context, content);

      case _GuidelineMenuAction.notes:
        await _editNotes(context, notes);

      case _GuidelineMenuAction.share:
        await _copyLink(context);

      case _GuidelineMenuAction.original:
        await _openOriginal(context);
    }
  }

  Future<void> _showContents(
    BuildContext context,
    GuidelinePublicationContent content,
  ) async {
    if (content.sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No structured chapters are available.')),
      );
      return;
    }

    final sectionId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _GuidelineContentsSheet(
          sections: content.sections,
          currentSectionId: _currentSectionId ?? _selectedSectionId,
        );
      },
    );

    if (!mounted || sectionId == null) return;

    await _goToSection(content.sections, sectionId);
  }

  Future<void> _showMoreActions(
    BuildContext context,
    GuidelinePublicationContent content,
    String notes,
  ) async {
    final action = await showModalBottomSheet<_ReaderMoreAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return const _ReaderMoreActionsSheet();
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ReaderMoreAction.notes:
        await _editNotes(context, notes);

      case _ReaderMoreAction.download:
        await _download(context, content);

      case _ReaderMoreAction.share:
        await _copyLink(context);

      case _ReaderMoreAction.original:
        await _openOriginal(context);
    }
  }

  Future<void> _goToSection(
    List<PublicationSection> sections,
    String sectionId,
  ) async {
    final index = sections.indexWhere((section) => section.id == sectionId);

    if (index < 0) return;

    if (mounted) {
      setState(() {
        _selectedSectionId = sectionId;
      });
    }

    final sectionContext = _sectionKeys[sectionId]?.currentContext;

    if (sectionContext != null) {
      await Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );

      _scheduleProgressUpdate(sections, sectionId);

      return;
    }

    //
    // SliverList lazily builds its children. A distant section may therefore
    // not have a BuildContext yet. First move approximately toward it.
    //
    if (_readerScrollController.hasClients && sections.length > 1) {
      final maxExtent = _readerScrollController.position.maxScrollExtent;

      final fraction = index / (sections.length - 1);

      final approximateOffset = (maxExtent * fraction).clamp(0.0, maxExtent);

      await _readerScrollController.animateTo(
        approximateOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final target = _sectionKeys[sectionId]?.currentContext;

      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }

      _scheduleProgressUpdate(sections, sectionId);
    });
  }

  void _scheduleInitialSectionScroll(List<PublicationSection> sections) {
    if (_initialSectionScrollScheduled) return;

    final requested = _selectedSectionId;

    if (requested == null ||
        !sections.any((section) => section.id == requested)) {
      return;
    }

    _initialSectionScrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(_goToSection(sections, requested));
    });
  }

  void _scheduleInitialProgress(List<PublicationSection> sections) {
    if (_initialProgressScheduled || sections.isEmpty) {
      return;
    }

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

      _scheduleProgressUpdate(sections, sectionId);
    });
  }

  void _trackVisibleSection(List<PublicationSection> sections) {
    if (!mounted || sections.isEmpty) {
      return;
    }

    String? nearest;
    var distance = double.infinity;

    for (final section in sections) {
      final target = _sectionKeys[section.id]?.currentContext;
      final renderObject = target?.findRenderObject();

      if (renderObject is! RenderBox || !renderObject.attached) {
        continue;
      }

      final dy = renderObject.localToGlobal(Offset.zero).dy;

      //
      // Approximate the space used by the AppBar + pinned reader header.
      //
      final candidate = (dy - 150).abs();

      if (candidate < distance) {
        distance = candidate;
        nearest = section.id;
      }
    }

    if (nearest == null || nearest == _currentSectionId) {
      return;
    }

    setState(() {
      _currentSectionId = nearest;
    });

    _scheduleProgressUpdate(sections, nearest);
  }

  void _scheduleProgressUpdate(
    List<PublicationSection> sections,
    String sectionId,
  ) {
    _progressDebounce?.cancel();

    _progressDebounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      unawaited(_recordSectionProgress(sections, sectionId));
    });
  }

  Future<void> _recordSectionProgress(
    List<PublicationSection> sections,
    String sectionId,
  ) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null || sections.isEmpty) {
      return;
    }

    final index = sections.indexWhere((section) => section.id == sectionId);

    final progress = index < 0
        ? 0.0
        : ((index + 1) / sections.length).clamp(0.0, 1.0);

    await ref
        .read(readingProgressRepositoryProvider)
        .upsert(user.id, widget.guidelineId, {
          'current_section': sectionId,
          'total_sections': sections.length,
          'progress_percentage': progress,
          'last_read_at': DateTime.now().toUtc().toIso8601String(),
        });

    if (!mounted) return;

    ref.invalidate(publicationReadingProgressProvider(widget.guidelineId));
  }

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

      if (!mounted || !context.mounted) return;

      final message = result.status == OfflineDownloadStatus.ready
          ? 'Verified offline copy is ready.'
          : 'Download ${result.status.name}.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted || !context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    }
  }

  void _openAiAssistant(
    BuildContext context,
    GuidelinePublicationContent content,
  ) {
    final publication = content.publication;

    final sectionId = _currentSectionId ?? _selectedSectionId;

    final selectedSection = _findSection(content.sections, sectionId);

    final relevantBlocks = selectedSection == null
        ? content.blocks
        : content.blocksFor(selectedSection.id);

    final referenceContent = <String>[
      publication.description,
      if (publication.sourceOrganization.isNotEmpty)
        'Source: ${publication.sourceOrganization}',
      if (publication.version.isNotEmpty) 'Version: ${publication.version}',
      if (selectedSection != null) 'Current section: ${selectedSection.title}',
      ...relevantBlocks.map(_searchableBlockText),
    ].where((value) => value.trim().isNotEmpty).join('\n\n');

    final aiContext = AiContext.guideline(
      title: selectedSection == null
          ? publication.title
          : '${publication.title} — ${selectedSection.title}',
      content: referenceContent.isEmpty
          ? 'Use approved MediGuide sources and cite the supporting guideline.'
          : referenceContent,
      guidelineId: widget.guidelineId,
      metadata: <String, dynamic>{
        'guideline_id': widget.guidelineId,
        'program_area': publication.programArea,
        'country': publication.country,
        'version': publication.version,
        if (selectedSection != null) 'section_id': selectedSection.id,
        'reviewed_content':
            content.manifest.recommendedMode == GuidelineReaderMode.structured,
      },
    );

    context.push(
      AppRoutes.aiAssistant,
      extra: <String, dynamic>{'aiContext': aiContext.toJson()},
    );
  }

  Future<void> _openOriginal(BuildContext context) async {
    try {
      final asset = await ref.read(
        guidelineOriginalDocumentProvider(widget.guidelineId).future,
      );

      if (!mounted || !context.mounted) return;

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
      if (!mounted || !context.mounted) return;

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

    if (!mounted) return;

    ref.invalidate(provider);
  }

  Future<void> _editNotes(BuildContext context, String current) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      _requireSignIn(context, 'Sign in to create private reading notes.');

      return;
    }

    var noteText = current;

    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.notebookPen),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        'Reading notes',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Text(
                  'Private notes are linked to your reading progress.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapMd,
                TextFormField(
                  initialValue: current,
                  minLines: 4,
                  maxLines: 10,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    noteText = value;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Add a private note about this guideline',
                    alignLabelWithHint: true,
                  ),
                ),
                AppSpacing.gapMd,
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop(noteText);
                  },
                  icon: const Icon(LucideIcons.save),
                  label: const Text('Save note'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || note == null) return;

    await ref.read(readingProgressRepositoryProvider).upsert(
      user.id,
      widget.guidelineId,
      {'notes': note.trim()},
    );

    if (!mounted) return;

    ref.invalidate(publicationReadingProgressProvider(widget.guidelineId));
  }

  Future<void> _copyLink(BuildContext context) async {
    final sectionId = _currentSectionId ?? _selectedSectionId;

    var link = AppRoutes.publicGuideline(widget.guidelineId);

    if (sectionId != null) {
      link = '$link?section=${Uri.encodeQueryComponent(sectionId)}';
    }

    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted || !context.mounted) return;

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

    if (!widget.readerOnly) {
      context.push(
        '${AppRoutes.readPublicGuideline(widget.guidelineId)}'
        '?section=${Uri.encodeQueryComponent(sectionId)}',
      );

      return;
    }

    await _goToSection(content.sections, sectionId);
  }

  PublicationSection? _findSection(
    List<PublicationSection> sections,
    String? id,
  ) {
    if (id == null) return null;

    for (final section in sections) {
      if (section.id == id) {
        return section;
      }
    }

    return null;
  }
}

enum _GuidelineMenuAction { search, notes, share, original }

enum _ReaderMoreAction { notes, download, share, original }

/// ---------------------------------------------------------------------------
/// Reader
/// ---------------------------------------------------------------------------

class _ReaderOverview extends StatelessWidget {
  const _ReaderOverview({required this.content});

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
        AppSpacing.lg,
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
            Text(
              publication.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (publication.sourceOrganization.isNotEmpty)
                Chip(
                  avatar: const Icon(LucideIcons.landmark, size: 16),
                  label: Text(publication.sourceOrganization),
                ),
              if (publication.version.isNotEmpty)
                Chip(label: Text('Version ${publication.version}')),
              _ReviewStatus(manifest: manifest),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReaderProgressHeader extends StatelessWidget {
  const _ReaderProgressHeader({
    required this.currentSection,
    required this.currentIndex,
    required this.totalSections,
    required this.progress,
    required this.onContents,
  });

  final PublicationSection? currentSection;
  final int currentIndex;
  final int totalSections;
  final double progress;
  final VoidCallback onContents;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          7,
          Responsive.horizontalPadding(context),
          7,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentIndex >= 0)
                        Text(
                          'Chapter ${currentIndex + 1} of $totalSections',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      Text(
                        currentSection?.title ?? 'Guideline contents',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                TextButton.icon(
                  onPressed: onContents,
                  icon: const Icon(LucideIcons.listTree, size: 18),
                  label: const Text('Contents'),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: progress, minHeight: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineReaderSection extends StatelessWidget {
  const _GuidelineReaderSection({
    required this.guidelineId,
    required this.section,
    required this.blocks,
    required this.isCurrent,
  });

  final String guidelineId;
  final PublicationSection section;
  final List<GuidelineBlock> blocks;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.level > 1)
            Text(
              'SECTION',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          Semantics(
            header: true,
            child: Text(
              section.title,
              style: section.level <= 1
                  ? Theme.of(context).textTheme.headlineSmall
                  : Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (section.pageLabel.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  section.pageLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.gapMd,
          if (blocks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: const Text(
                'No reviewed content is available for this section.',
              ),
            )
          else
            for (final block in blocks) ...[
              PublicationBlockView(block: block, guidelineId: guidelineId),
              AppSpacing.gapLg,
            ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Contents
/// ---------------------------------------------------------------------------

class _GuidelineContentsSheet extends StatelessWidget {
  const _GuidelineContentsSheet({
    required this.sections,
    required this.currentSectionId,
  });

  final List<PublicationSection> sections;
  final String? currentSectionId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contents',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${sections.length} sections',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];

                  final selected = section.id == currentSectionId;

                  final indentation = ((section.level - 1).clamp(0, 5) * 16)
                      .toDouble();

                  return Padding(
                    padding: EdgeInsets.only(left: indentation),
                    child: ListTile(
                      selected: selected,
                      leading: selected
                          ? Icon(
                              LucideIcons.circleDot,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            )
                          : Icon(
                              section.level <= 1
                                  ? LucideIcons.bookOpen
                                  : LucideIcons.cornerDownRight,
                              size: 18,
                            ),
                      title: Text(
                        section.title,
                        style: selected
                            ? const TextStyle(fontWeight: FontWeight.w600)
                            : null,
                      ),
                      subtitle: section.pageLabel.isEmpty
                          ? null
                          : Text(section.pageLabel),
                      trailing: const Icon(LucideIcons.chevronRight, size: 18),
                      onTap: () {
                        Navigator.of(context).pop(section.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Reader actions
/// ---------------------------------------------------------------------------

class _ReaderActionBar extends StatelessWidget {
  const _ReaderActionBar({
    required this.isBookmarked,
    required this.onContents,
    required this.onAskAi,
    required this.onBookmark,
    required this.onMore,
  });

  final bool isBookmarked;

  final VoidCallback onContents;
  final VoidCallback onAskAi;
  final VoidCallback onBookmark;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final actions = <_Action>[
      _Action(icon: LucideIcons.listTree, label: 'Contents', onTap: onContents),
      _Action(icon: LucideIcons.sparkles, label: 'Ask AI', onTap: onAskAi),
      _Action(
        icon: isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
        label: 'Bookmark',
        onTap: onBookmark,
      ),
      _Action(icon: LucideIcons.ellipsis, label: 'More', onTap: onMore),
    ];

    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [for (final action in actions) Expanded(child: action)],
          ),
        ),
      ),
    );
  }
}

class _OverviewActionBar extends StatelessWidget {
  const _OverviewActionBar({required this.onRead, required this.onDownload});

  final VoidCallback onRead;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onRead,
                  icon: const Icon(LucideIcons.bookOpenText),
                  label: const Text('Read guideline'),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(LucideIcons.download),
                  label: const Text('Offline'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderMoreActionsSheet extends StatelessWidget {
  const _ReaderMoreActionsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.notebookPen),
              title: const Text('Reading notes'),
              subtitle: const Text('Add or update private notes'),
              onTap: () {
                Navigator.of(context).pop(_ReaderMoreAction.notes);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.download),
              title: const Text('Download for offline use'),
              onTap: () {
                Navigator.of(context).pop(_ReaderMoreAction.download);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.share2),
              title: const Text('Copy guideline link'),
              onTap: () {
                Navigator.of(context).pop(_ReaderMoreAction.share);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileText),
              title: const Text('Open original document'),
              subtitle: const Text('View the authoritative source document'),
              onTap: () {
                Navigator.of(context).pop(_ReaderMoreAction.original);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Overview
/// ---------------------------------------------------------------------------

class _GuidelineOverview extends StatefulWidget {
  const _GuidelineOverview({
    required this.content,
    required this.isBookmarked,
    required this.onRead,
    required this.onSection,
    required this.onOriginal,
    required this.onDownload,
    required this.onBookmark,
  });

  final GuidelinePublicationContent content;
  final bool isBookmarked;

  final VoidCallback onRead;
  final ValueChanged<String> onSection;
  final VoidCallback onOriginal;
  final VoidCallback onDownload;
  final VoidCallback onBookmark;

  @override
  State<_GuidelineOverview> createState() => _GuidelineOverviewState();
}

class _GuidelineOverviewState extends State<_GuidelineOverview> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final publication = widget.content.publication;

    final manifest = widget.content.manifest;

    final keyRecommendations = widget.content.blocks
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

    final tables = widget.content.blocks
        .whereType<TableGuidelineBlock>()
        .toList(growable: false);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        AppSpacing.lg,
        Responsive.horizontalPadding(context),
        AppSpacing.xxxl,
      ),
      children: [
        _GuidelineHero(
          publication: publication,
          manifest: manifest,
          isBookmarked: widget.isBookmarked,
          onRead: widget.onRead,
          onDownload: widget.onDownload,
          onBookmark: widget.onBookmark,
        ),

        AppSpacing.gapXl,

        _GuidelineTabs(
          selectedIndex: _selectedTab,
          hasKeyPoints: keyRecommendations.isNotEmpty,
          hasTables: tables.isNotEmpty,
          onSelected: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
        ),

        AppSpacing.gapLg,

        switch (_selectedTab) {
          1 => _ChapterList(
            sections: widget.content.sections,
            onSection: widget.onSection,
          ),
          2 => _KeyPointList(blocks: keyRecommendations),
          3 => _TableList(tables: tables),
          _ => _GuidelineAbout(
            publication: publication,
            recommendations: keyRecommendations,
          ),
        },

        if (manifest.hasOriginalPdf) ...[
          AppSpacing.gapXl,
          const Divider(),
          AppSpacing.gapSm,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.fileText),
            title: const Text('Original source document'),
            subtitle: const Text('Open the authoritative source document.'),
            trailing: const Icon(LucideIcons.externalLink, size: 18),
            onTap: widget.onOriginal,
          ),
        ],
      ],
    );
  }
}

class _GuidelineHero extends StatelessWidget {
  const _GuidelineHero({
    required this.publication,
    required this.manifest,
    required this.isBookmarked,
    required this.onRead,
    required this.onDownload,
    required this.onBookmark,
  });

  final GuidelinePublication publication;
  final GuidelineManifest manifest;
  final bool isBookmarked;

  final VoidCallback onRead;
  final VoidCallback onDownload;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final metadata = <String>[
      if (publication.sourceOrganization.isNotEmpty)
        publication.sourceOrganization,
      if (publication.publicationDate.isNotEmpty) publication.publicationDate,
      if (publication.version.isNotEmpty) 'v${publication.version}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          publication.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        if (metadata.isNotEmpty) ...[
          AppSpacing.gapSm,
          Text(
            metadata.join('  •  '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        AppSpacing.gapMd,

        _ReviewStatus(manifest: manifest),

        if (publication.description.isNotEmpty) ...[
          AppSpacing.gapMd,
          Text(
            publication.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],

        AppSpacing.gapLg,

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRead,
            icon: const Icon(LucideIcons.bookOpenText),
            label: const Text('Read guideline'),
          ),
        ),

        AppSpacing.gapSm,

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(LucideIcons.download),
                label: const Text('Offline'),
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBookmark,
                icon: Icon(
                  isBookmarked
                      ? LucideIcons.bookmarkCheck
                      : LucideIcons.bookmark,
                ),
                label: Text(isBookmarked ? 'Saved' : 'Bookmark'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GuidelineTabs extends StatelessWidget {
  const _GuidelineTabs({
    required this.selectedIndex,
    required this.hasKeyPoints,
    required this.hasTables,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool hasKeyPoints;
  final bool hasTables;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, bool)>[
      ('Overview', true),
      ('Chapters', true),
      ('Key Points', hasKeyPoints),
      ('Tables', hasTables),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < tabs.length; index++)
              InkWell(
                onTap: tabs[index].$2
                    ? () {
                        onSelected(index);
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: selectedIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[index].$1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: !tabs[index].$2
                          ? Theme.of(context).disabledColor
                          : selectedIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineAbout extends StatelessWidget {
  const _GuidelineAbout({
    required this.publication,
    required this.recommendations,
  });

  final GuidelinePublication publication;

  final List<CalloutGuidelineBlock> recommendations;

  @override
  Widget build(BuildContext context) {
    final facts = <(String, String)>[
      ('Purpose', publication.description),
      ('Target users', publication.intendedPopulation),
      ('Applies to', publication.healthcareLevel),
      ('Language', publication.language),
      ('Program area', publication.programArea),
      ('Review date', publication.reviewDate),
    ].where((item) => item.$2.trim().isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this guideline',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        AppSpacing.gapMd,

        for (final fact in facts) ...[
          Text(
            fact.$1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(fact.$2, style: Theme.of(context).textTheme.bodyMedium),
          AppSpacing.gapMd,
        ],

        if (recommendations.isNotEmpty) ...[
          AppSpacing.gapSm,
          Text(
            'Key recommendations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.gapSm,
          for (final block in recommendations)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.circleCheck,
                    size: 19,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AppSpacing.hGapSm,
                  Expanded(child: Text(block.payload.content)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.sections, required this.onSection});

  final List<PublicationSection> sections;
  final ValueChanged<String> onSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chapters', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        if (sections.isEmpty) const Text('No structured chapters available.'),
        for (var i = 0; i < sections.length; i++)
          Padding(
            padding: EdgeInsets.only(
              left: ((sections[i].level - 1).clamp(0, 5) * 12).toDouble(),
            ),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: sections[i].level <= 1
                  ? CircleAvatar(
                      radius: 14,
                      child: Text(
                        '${i + 1}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    )
                  : const Icon(LucideIcons.cornerDownRight, size: 17),
              title: Text(sections[i].title),
              subtitle: sections[i].pageLabel.isEmpty
                  ? null
                  : Text(sections[i].pageLabel),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () {
                onSection(sections[i].id);
              },
            ),
          ),
      ],
    );
  }
}

class _KeyPointList extends StatelessWidget {
  const _KeyPointList({required this.blocks});

  final List<CalloutGuidelineBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Key points', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        if (blocks.isEmpty) const Text('No reviewed key points available.'),
        for (final block in blocks)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: const Icon(LucideIcons.circleCheck),
              title: Text(
                block.payload.title.isEmpty ? 'Key point' : block.payload.title,
              ),
              subtitle: Text(block.payload.content),
            ),
          ),
      ],
    );
  }
}

class _TableList extends StatelessWidget {
  const _TableList({required this.tables});

  final List<TableGuidelineBlock> tables;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tables', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        if (tables.isEmpty) const Text('No reviewed tables available.'),
        for (final table in tables)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: const Icon(LucideIcons.table2),
              title: Text(
                table.payload.title.isEmpty
                    ? 'Clinical table'
                    : table.payload.title,
              ),
              subtitle: Text(
                '${table.payload.rows.length} rows'
                ' • '
                '${table.payload.columns.length} columns',
              ),
            ),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Review status
/// ---------------------------------------------------------------------------

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

/// ---------------------------------------------------------------------------
/// Original document fallback
/// ---------------------------------------------------------------------------

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
  Widget build(BuildContext context) {
    return Center(
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
                'Reviewed structured extraction is not available. '
                'Use the original document as the clinical source.',
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
                  if ((asset?.sizeBytes ?? 0) > 0)
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
}

/// ---------------------------------------------------------------------------
/// Search
/// ---------------------------------------------------------------------------

class _GuidelineContentSearchDelegate extends SearchDelegate<String?> {
  _GuidelineContentSearchDelegate(this.content);

  final GuidelinePublicationContent content;

  @override
  String get searchFieldLabel => 'Search reviewed guideline content';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear search',
          onPressed: () {
            query = '';
          },
          icon: const Icon(LucideIcons.x),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Close search',
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(LucideIcons.arrowLeft),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _results(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _results(context);
  }

  Widget _results(BuildContext context) {
    final needle = query.trim().toLowerCase();

    if (needle.isEmpty) {
      return const _SearchEmptyState(
        icon: LucideIcons.search,
        title: 'Search this guideline',
        message:
            'Search reviewed sections, recommendations, tables, and clinical text.',
      );
    }

    final matches = <_GuidelineSearchResult>[];

    for (final section in content.sections) {
      final sectionTitle = section.title.toLowerCase();

      if (sectionTitle.contains(needle)) {
        matches.add(
          _GuidelineSearchResult(section: section, snippet: section.title),
        );

        continue;
      }

      for (final block in content.blocksFor(section.id)) {
        final text = _searchableBlockText(block);

        final lowerText = text.toLowerCase();

        final index = lowerText.indexOf(needle);

        if (index >= 0) {
          matches.add(
            _GuidelineSearchResult(
              section: section,
              snippet: _searchSnippet(text, index, needle.length),
            ),
          );

          break;
        }
      }
    }

    if (matches.isEmpty) {
      return const _SearchEmptyState(
        icon: LucideIcons.searchX,
        title: 'No matches',
        message: 'No matching reviewed content was found in this guideline.',
      );
    }

    return ListView.separated(
      itemCount: matches.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final match = matches[index];

        return ListTile(
          leading: const Icon(LucideIcons.fileSearch),
          title: Text(match.section.title),
          subtitle: Text(
            match.snippet,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: match.section.pageLabel.isEmpty
              ? const Icon(LucideIcons.chevronRight, size: 18)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.section.pageLabel,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const Icon(LucideIcons.chevronRight, size: 16),
                  ],
                ),
          onTap: () {
            close(context, match.section.id);
          },
        );
      },
    );
  }
}

class _GuidelineSearchResult {
  const _GuidelineSearchResult({required this.section, required this.snippet});

  final PublicationSection section;
  final String snippet;
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
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
                size: 44,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              AppSpacing.gapMd,
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.gapSm,
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

/// ---------------------------------------------------------------------------
/// Helpers
/// ---------------------------------------------------------------------------

String _searchSnippet(String text, int matchIndex, int matchLength) {
  if (text.isEmpty) return '';

  const radius = 85;

  final start = (matchIndex - radius).clamp(0, text.length);

  final end = (matchIndex + matchLength + radius).clamp(0, text.length);

  var result = text
      .substring(start, end)
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (start > 0) {
    result = '…$result';
  }

  if (end < text.length) {
    result = '$result…';
  }

  return result;
}

String _searchableBlockText(GuidelineBlock block) {
  return switch (block) {
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
      '${payload.caption} '
          '${payload.alternativeText}',

    CalloutGuidelineBlock(:final payload) =>
      '${payload.title} '
          '${payload.content}',

    AlgorithmGuidelineBlock(:final payload) => [
      payload.title,
      ...payload.nodes.map((node) => node.label),
    ].join(' '),

    ReferenceGuidelineBlock(:final citation) => citation,

    PageBreakGuidelineBlock(:final page) => 'Page $page',

    UnknownGuidelineBlock() => '',
  };
}

String _fileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// ---------------------------------------------------------------------------
/// Sliver delegates
/// ---------------------------------------------------------------------------

class _ReaderHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ReaderHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 74;

  @override
  double get maxExtent => 74;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ReaderHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
