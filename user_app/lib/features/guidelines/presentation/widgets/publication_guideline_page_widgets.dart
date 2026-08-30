part of '../screens/publication_guideline_page.dart';

enum _GuidelineMenuAction { search, notes, share, original }

// =============================================================================
// SEARCH DELEGATE
// =============================================================================

class _GuidelineContentSearchDelegate extends SearchDelegate<String?> {
  _GuidelineContentSearchDelegate(this.content);

  final GuidelinePublicationContent content;

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
          onTap: () {
            close(context, match.section.id);
          },
        );
      },
    );
  }
}

// =============================================================================
// SEARCHABLE CONTENT
// =============================================================================

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
}

// =============================================================================
// NOTES SHEET
// =============================================================================

class _ReadingNotesSheet extends StatefulWidget {
  const _ReadingNotesSheet({required this.initialValue});

  final String initialValue;

  @override
  State<_ReadingNotesSheet> createState() => _ReadingNotesSheetState();
}

class _ReadingNotesSheetState extends State<_ReadingNotesSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reading notes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),

          AppSpacing.gapSm,

          Text(
            'Private notes are saved with your reading progress.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          AppSpacing.gapMd,

          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 8,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add a private note about this guideline',
              border: OutlineInputBorder(),
            ),
          ),

          AppSpacing.gapMd,

          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context, _controller.text);
            },
            icon: const Icon(LucideIcons.check),
            label: const Text('Save note'),
          ),

          AppSpacing.gapSm,
        ],
      ),
    );
  }
}

// =============================================================================
// GUIDELINE OVERVIEW
// =============================================================================

class _GuidelineOverview extends StatefulWidget {
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
        AppSpacing.md,
        Responsive.horizontalPadding(context),

        // Bottom bar spacing.
        AppSpacing.xxxl + 72,
      ),
      children: [
        // ===================================================================
        // TITLE
        // ===================================================================
        Text(
          publication.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        // ===================================================================
        // METADATA
        // ===================================================================
        AppSpacing.gapSm,

        Text(
          [
            if (publication.sourceOrganization.isNotEmpty)
              publication.sourceOrganization,

            if (publication.publicationDate.isNotEmpty)
              publication.publicationDate,

            if (publication.version.isNotEmpty) 'v${publication.version}',
          ].join('  •  '),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),

        AppSpacing.gapMd,

        // ===================================================================
        // REVIEW STATUS
        // ===================================================================
        _ReviewStatus(manifest: manifest),

        // ===================================================================
        // DESCRIPTION
        // ===================================================================
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

        // ===================================================================
        // TABS
        // ===================================================================
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

        // ===================================================================
        // TAB CONTENT
        // ===================================================================
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

        //
        // Deliberately no Read / Offline / Bookmark buttons here.
        //
        // Those actions now live in the persistent bottom action bar.
        //
      ],
    );
  }
}

// =============================================================================
// TABS
// =============================================================================

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
                      fontWeight: selectedIndex == index
                          ? FontWeight.w700
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

// =============================================================================
// ABOUT
// =============================================================================

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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        AppSpacing.gapLg,

        for (final fact in facts) ...[
          Text(
            fact.$1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            fact.$2,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),

          AppSpacing.gapLg,
        ],

        if (recommendations.isNotEmpty) ...[
          Text(
            'Key recommendations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),

          AppSpacing.gapSm,

          for (final block in recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.check,
                    size: 18,
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

// =============================================================================
// CHAPTERS
// =============================================================================

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.sections, required this.onSection});

  final List<PublicationSection> sections;

  final ValueChanged<String> onSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapters',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        AppSpacing.gapSm,

        if (sections.isEmpty) const Text('No structured chapters available.'),

        for (final section in sections)
          Padding(
            padding: EdgeInsets.only(
              left: ((section.level - 1).clamp(0, 5)) * 12.0,
            ),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(section.title),
              subtitle: section.pageLabel.isEmpty
                  ? null
                  : Text(section.pageLabel),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () {
                onSection(section.id);
              },
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// KEY POINTS
// =============================================================================

class _KeyPointList extends StatelessWidget {
  const _KeyPointList({required this.blocks});

  final List<CalloutGuidelineBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key points',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        AppSpacing.gapSm,

        if (blocks.isEmpty) const Text('No reviewed key points available.'),

        for (final block in blocks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
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

// =============================================================================
// TABLES
// =============================================================================

class _TableList extends StatelessWidget {
  const _TableList({required this.tables});

  final List<TableGuidelineBlock> tables;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tables',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        AppSpacing.gapSm,

        if (tables.isEmpty) const Text('No reviewed tables available.'),

        for (final table in tables)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
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

// =============================================================================
// REVIEW STATUS
// =============================================================================

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

    return Align(
      alignment: Alignment.centerLeft,
      child: AppStatusBadge(icon: icon, tone: tone, label: label),
    );
  }
}

// =============================================================================
// NEW BOTTOM ACTION BAR
// =============================================================================

class _ReaderActionBar extends StatelessWidget {
  const _ReaderActionBar({
    required this.isBookmarked,
    required this.offlineDownload,
    required this.showRead,
    required this.onRead,
    required this.onAskAi,
    required this.onBookmark,
    required this.onNotes,
    required this.onShare,
    required this.onOriginal,
    required this.onDownload,
  });

  final bool isBookmarked;
  final OfflineDownload? offlineDownload;
  final bool showRead;

  final VoidCallback onRead;
  final VoidCallback onAskAi;
  final VoidCallback onBookmark;
  final VoidCallback onNotes;
  final VoidCallback onShare;
  final VoidCallback onOriginal;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: showRead
              ? _OverviewBottomActions(
                  isBookmarked: isBookmarked,
                  offlineDownload: offlineDownload,
                  onRead: onRead,
                  onBookmark: onBookmark,
                  onDownload: onDownload,
                  onMore: () {
                    _showMoreActions(context);
                  },
                )
              : _ReadingBottomActions(
                  isBookmarked: isBookmarked,
                  onAskAi: onAskAi,
                  onBookmark: onBookmark,
                  onNotes: onNotes,
                  onMore: () {
                    _showMoreActions(context);
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _showMoreActions(BuildContext context) {
    final status = offlineDownload?.status;
    final downloading =
        status == OfflineDownloadStatus.queued ||
        status == OfflineDownloadStatus.downloading;
    final offlineTitle = switch (status) {
      OfflineDownloadStatus.ready => 'Manage offline copy',
      OfflineDownloadStatus.updateAvailable => 'Update offline copy',
      OfflineDownloadStatus.failed ||
      OfflineDownloadStatus.corrupted => 'Retry offline copy',
      OfflineDownloadStatus.queued ||
      OfflineDownloadStatus.downloading => 'Downloading offline copy',
      _ => 'Download for offline use',
    };
    final offlineSubtitle = switch (status) {
      OfflineDownloadStatus.ready => 'Saved and available without internet',
      OfflineDownloadStatus.updateAvailable =>
        'A newer published version is available',
      OfflineDownloadStatus.failed || OfflineDownloadStatus.corrupted =>
        'The previous download did not complete',
      OfflineDownloadStatus.queued ||
      OfflineDownloadStatus.downloading => 'The verified file is being saved',
      _ => 'Save a verified copy on this device',
    };
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: [
              ListTile(
                leading: const Icon(LucideIcons.sparkles),
                title: const Text('Ask AI'),
                subtitle: const Text(
                  'Ask questions using this guideline as context',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onAskAi();
                },
              ),

              ListTile(
                leading: const Icon(LucideIcons.notebookPen),
                title: const Text('Reading notes'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onNotes();
                },
              ),

              ListTile(
                leading: const Icon(LucideIcons.share2),
                title: const Text('Share guideline'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onShare();
                },
              ),

              ListTile(
                leading: const Icon(LucideIcons.fileText),
                title: const Text('Open original document'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  onOriginal();
                },
              ),

              ListTile(
                leading: Icon(
                  status == OfflineDownloadStatus.ready
                      ? LucideIcons.cloudCheck
                      : status == OfflineDownloadStatus.updateAvailable
                      ? LucideIcons.refreshCw
                      : LucideIcons.download,
                ),
                title: Text(offlineTitle),
                subtitle: Text(offlineSubtitle),
                onTap: downloading
                    ? null
                    : () {
                        Navigator.pop(sheetContext);

                        onDownload();
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// OVERVIEW BOTTOM ACTIONS
// =============================================================================

class _OverviewBottomActions extends StatelessWidget {
  const _OverviewBottomActions({
    required this.isBookmarked,
    required this.offlineDownload,
    required this.onRead,
    required this.onBookmark,
    required this.onDownload,
    required this.onMore,
  });

  final bool isBookmarked;
  final OfflineDownload? offlineDownload;

  final VoidCallback onRead;
  final VoidCallback onBookmark;
  final VoidCallback onDownload;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onRead,
            icon: const Icon(LucideIcons.bookOpenText, size: 19),
            label: const Text('Read guideline'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),

        AppSpacing.hGapSm,

        _BottomIconAction(
          icon: isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
          onTap: onBookmark,
        ),

        AppSpacing.hGapXs,

        _BottomIconAction(
          icon: offlineDownload?.status == OfflineDownloadStatus.ready
              ? LucideIcons.cloudCheck
              : LucideIcons.download,
          tooltip: offlineDownload?.status == OfflineDownloadStatus.ready
              ? 'Manage offline copy'
              : 'Download for offline use',
          onTap: onDownload,
        ),

        AppSpacing.hGapXs,

        _BottomIconAction(
          icon: LucideIcons.ellipsis,
          tooltip: 'More',
          onTap: onMore,
        ),
      ],
    );
  }
}

// =============================================================================
// READER BOTTOM ACTIONS
// =============================================================================

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

class _BottomIconAction extends StatelessWidget {
  const _BottomIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 20, color: colors.primary),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// READER BOTTOM ACTION
// =============================================================================

class _ReaderBottomAction extends StatelessWidget {
  const _ReaderBottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: colors.primary),

              const SizedBox(height: 3),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// READER OVERVIEW HEADER
// =============================================================================

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
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
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

// =============================================================================
// ORIGINAL DOCUMENT READER
// =============================================================================

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

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FILE SIZE
// =============================================================================

String _fileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// =============================================================================
// SECTION HEADER DELEGATE
// =============================================================================

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
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
