part of '../screens/publication_guideline_page.dart';

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
