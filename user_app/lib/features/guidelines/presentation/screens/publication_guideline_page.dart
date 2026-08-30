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

part '../widgets/publication_guideline_page_guideline_menu_action.dart';
part '../widgets/publication_guideline_page_guideline_content_search_delegate.dart';
part '../widgets/publication_guideline_page_reading_notes_sheet.dart';
part '../widgets/publication_guideline_page_reading_notes_sheet_state.dart';
part '../widgets/publication_guideline_page_guideline_overview.dart';
part '../widgets/publication_guideline_page_guideline_overview_state.dart';
part '../widgets/publication_guideline_page_guideline_tabs.dart';
part '../widgets/publication_guideline_page_guideline_about.dart';
part '../widgets/publication_guideline_page_chapter_list.dart';
part '../widgets/publication_guideline_page_key_point_list.dart';
part '../widgets/publication_guideline_page_table_list.dart';
part '../widgets/publication_guideline_page_review_status.dart';
part '../widgets/publication_guideline_page_reader_action_bar.dart';
part '../widgets/publication_guideline_page_overview_bottom_actions.dart';
part '../widgets/publication_guideline_page_reading_bottom_actions.dart';
part '../widgets/publication_guideline_page_bottom_icon_action.dart';
part '../widgets/publication_guideline_page_reader_bottom_action.dart';
part '../widgets/publication_guideline_page_overview.dart';
part '../widgets/publication_guideline_page_original_document_reader.dart';
part '../widgets/publication_guideline_page_section_header_delegate.dart';

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

    if (_deepLinkApplied) {
      return;
    }

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
    final downloadItems = ref
        .watch(guidelineDownloadsControllerProvider)
        .valueOrNull;
    final currentContent = content.valueOrNull;
    final targetAssetType = currentContent?.manifest.hasOfflinePackage == true
        ? 'offline_package'
        : 'original_pdf';
    OfflineDownload? offlineDownload;
    for (final item in downloadItems ?? const <OfflineDownload>[]) {
      if (item.guidelineId == widget.guidelineId &&
          item.assetType == targetAssetType) {
        offlineDownload = item;
        break;
      }
    }

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
            onPressed: () {
              _toggleBookmark(context);
            },
            icon: Icon(
              progress?.isBookmarked == true
                  ? LucideIcons.bookmarkCheck
                  : LucideIcons.bookmark,
            ),
          ),

          PopupMenuButton<_GuidelineMenuAction>(
            tooltip: 'More guideline actions',
            onSelected: (action) {
              _handleMenuAction(
                context,
                action,
                content.valueOrNull,
                progress?.notes ?? '',
              );
            },
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

      // =====================================================================
      // BODY
      // =====================================================================
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
            return _content(context, value);
          }

          return _overviewPage(context, value, progress?.isBookmarked == true);
        },
      ),

      // =====================================================================
      // BOTTOM ACTION BAR
      // =====================================================================
      bottomNavigationBar: content.valueOrNull == null
          ? null
          : _ReaderActionBar(
              isBookmarked: progress?.isBookmarked == true,
              offlineDownload: offlineDownload,
              showRead: !widget.readerOnly,
              onRead: () {
                context.push(AppRoutes.readPublicGuideline(widget.guidelineId));
              },
              onAskAi: () {
                _openAiAssistant(context, content.requireValue);
              },
              onBookmark: () {
                _toggleBookmark(context);
              },
              onNotes: () {
                _editNotes(context, progress?.notes ?? '');
              },
              onShare: () {
                _copyLink(context);
              },
              onOriginal: () {
                _openOriginal(context);
              },
              onDownload: () {
                if (offlineDownload?.status == OfflineDownloadStatus.ready) {
                  context.push(AppRoutes.offlineContent);
                  return;
                }
                if (offlineDownload?.status ==
                        OfflineDownloadStatus.downloading ||
                    offlineDownload?.status == OfflineDownloadStatus.queued) {
                  return;
                }
                _download(context, content.requireValue);
              },
            ),
    );
  }

  // ===========================================================================
  // MENU
  // ===========================================================================

  Future<void> _handleMenuAction(
    BuildContext context,
    _GuidelineMenuAction action,
    GuidelinePublicationContent? content,
    String notes,
  ) async {
    switch (action) {
      case _GuidelineMenuAction.search:
        if (content != null) {
          await _searchWithin(context, content);
        }

      case _GuidelineMenuAction.notes:
        await _editNotes(context, notes);

      case _GuidelineMenuAction.share:
        await _copyLink(context);

      case _GuidelineMenuAction.original:
        await _openOriginal(context);
    }
  }

  // ===========================================================================
  // OVERVIEW
  // ===========================================================================

  Widget _overviewPage(
    BuildContext context,
    GuidelinePublicationContent value,
    bool isBookmarked,
  ) {
    return _GuidelineOverview(
      content: value,
      isBookmarked: isBookmarked,
      onRead: () {
        context.push(AppRoutes.readPublicGuideline(widget.guidelineId));
      },
      onSection: (sectionId) {
        context.push(
          '${AppRoutes.readPublicGuideline(widget.guidelineId)}'
          '?section=${Uri.encodeQueryComponent(sectionId)}',
        );
      },
      onOriginal: () {
        _openOriginal(context);
      },
    );
  }

  // ===========================================================================
  // DOWNLOAD
  // ===========================================================================

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

      if (!context.mounted) {
        return;
      }

      final message = result.status == OfflineDownloadStatus.ready
          ? 'Verified offline copy is ready.'
          : 'Download ${result.status.name}.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The offline copy could not be downloaded. '
            'Check your connection and try again.',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // AI
  // ===========================================================================

  void _openAiAssistant(
    BuildContext context,
    GuidelinePublicationContent content,
  ) {
    final publication = content.publication;

    final sectionId = _currentSectionId ?? _selectedSectionId;

    final selectedSection = sectionId == null
        ? null
        : content.sections
              .where((section) => section.id == sectionId)
              .firstOrNull;

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

  // ===========================================================================
  // READER
  // ===========================================================================

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
        onOpen: () {
          _openOriginal(context);
        },
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _trackVisibleSection(sections);
          });
        }

        return false;
      },
      child: CustomScrollView(
        controller: _readerScrollController,
        slivers: [
          SliverToBoxAdapter(child: _Overview(content: value)),

          // =================================================================
          // CURRENT SECTION
          // =================================================================
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
                    'Current section: '
                    '${sections.where((item) => item.id == _currentSectionId).map((item) => item.title).firstOrNull ?? ''}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),

          // =================================================================
          // SECTION NAVIGATION
          // =================================================================
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

                            setState(() {
                              _selectedSectionId = next;
                            });

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

          // =================================================================
          // CONTENT
          // =================================================================
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              AppSpacing.md,
              Responsive.horizontalPadding(context),

              // Extra breathing room above the persistent bottom bar.
              AppSpacing.xxxl + 72,
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

  // ===========================================================================
  // READING PROGRESS
  // ===========================================================================

  void _scheduleInitialProgress(List<PublicationSection> sections) {
    if (_initialProgressScheduled || sections.isEmpty) {
      return;
    }

    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      return;
    }

    final requested = _selectedSectionId;

    final sectionId =
        requested != null && sections.any((section) => section.id == requested)
        ? requested
        : sections.first.id;

    _initialProgressScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_recordSectionProgress(sections, sectionId));
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

      final box = target?.findRenderObject();

      if (box is! RenderBox || !box.attached) {
        continue;
      }

      final dy = box.localToGlobal(Offset.zero).dy;

      final candidate = (dy - 120).abs();

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

    if (user == null || sections.isEmpty) {
      return;
    }

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

    if (!mounted) {
      return;
    }
    ref.invalidate(publicationReadingProgressProvider(widget.guidelineId));
  }

  // ===========================================================================
  // ORIGINAL DOCUMENT
  // ===========================================================================

  Future<void> _openOriginal(BuildContext context) async {
    try {
      final asset = await ref.read(
        guidelineOriginalDocumentProvider(widget.guidelineId).future,
      );

      if (!context.mounted) {
        return;
      }

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
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The original document could not be opened. '
            'Check your connection and try again.',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // BOOKMARK
  // ===========================================================================

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

  // ===========================================================================
  // NOTES
  // ===========================================================================

  Future<void> _editNotes(BuildContext context, String current) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      _requireSignIn(context, 'Sign in to create private reading notes.');

      return;
    }

    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) {
        return _ReadingNotesSheet(initialValue: current);
      },
    );

    if (note == null || !mounted) {
      return;
    }

    await ref.read(readingProgressRepositoryProvider).upsert(
      user.id,
      widget.guidelineId,
      {'notes': note.trim()},
    );

    ref.invalidate(publicationReadingProgressProvider(widget.guidelineId));
  }

  // ===========================================================================
  // SHARE
  // ===========================================================================

  Future<void> _copyLink(BuildContext context) async {
    final link = AppRoutes.publicGuideline(widget.guidelineId);

    await Clipboard.setData(ClipboardData(text: link));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Guideline link copied.')));
  }

  // ===========================================================================
  // AUTH
  // ===========================================================================

  void _requireSignIn(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    final destination = Uri.encodeComponent(
      AppRoutes.publicGuideline(widget.guidelineId),
    );

    context.push(
      '${AppRoutes.login}'
      '?redirect=$destination',
    );
  }

  // ===========================================================================
  // SEARCH WITHIN
  // ===========================================================================

  Future<void> _searchWithin(
    BuildContext context,
    GuidelinePublicationContent content,
  ) async {
    final sectionId = await showSearch<String?>(
      context: context,
      delegate: _GuidelineContentSearchDelegate(content),
    );

    if (!mounted || sectionId == null) {
      return;
    }

    setState(() {
      _selectedSectionId = sectionId;
    });

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

// =============================================================================
// MENU ACTIONS
// =============================================================================
