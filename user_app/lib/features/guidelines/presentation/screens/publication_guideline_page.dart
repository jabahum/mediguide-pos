import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
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

class PublicationGuidelinePage extends ConsumerStatefulWidget {
  const PublicationGuidelinePage({super.key, required this.guidelineId});
  final String guidelineId;

  @override
  ConsumerState<PublicationGuidelinePage> createState() =>
      _PublicationGuidelinePageState();
}

class _PublicationGuidelinePageState
    extends ConsumerState<PublicationGuidelinePage> {
  String? _selectedSectionId;
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(publicationGuidelineProvider(widget.guidelineId));
    final progress = ref
        .watch(publicationReadingProgressProvider(widget.guidelineId))
        .valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical guideline'),
        actions: [
          IconButton(
            tooltip: 'Search within guideline',
            onPressed: content.valueOrNull == null
                ? null
                : () => _searchWithin(context, content.requireValue),
            icon: const Icon(LucideIcons.search),
          ),
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
          IconButton(
            tooltip: 'Reading notes',
            onPressed: () => _editNotes(context, progress?.notes ?? ''),
            icon: const Icon(LucideIcons.notebookPen),
          ),
          IconButton(
            tooltip: 'Copy link',
            onPressed: () => _copyLink(context),
            icon: const Icon(LucideIcons.share2),
          ),
          IconButton(
            tooltip: 'Open original document',
            onPressed: () => _openOriginal(context),
            icon: const Icon(LucideIcons.fileText),
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
        data: (value) => _content(context, value),
      ),
    );
  }

  Widget _content(BuildContext context, GuidelinePublicationContent value) {
    final mode = value.manifest.recommendedMode;
    if (mode == GuidelineReaderMode.originalDocument) {
      return _OriginalDocumentReader(
        publication: value.publication,
        hasOriginal: value.manifest.hasOriginalPdf,
        onOpen: () => _openOriginal(context),
      );
    }
    final sections = value.sections;
    final selected = _selectedSectionId;
    final visibleSections =
        mode == GuidelineReaderMode.structured && selected != null
        ? sections.where((section) => section.id == selected).toList()
        : sections;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Overview(content: value)),
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
                    itemCount: sections.length,
                    separatorBuilder: (_, _) => AppSpacing.gapSm,
                    itemBuilder: (_, index) {
                      final section = sections[index];
                      return ChoiceChip(
                        label: Text(section.title),
                        selected: selected == section.id,
                        onSelected: (_) => setState(() {
                          _selectedSectionId = selected == section.id
                              ? null
                              : section.id;
                        }),
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
                          PublicationBlockView(block: block),
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
    );
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
      await launchUrl(
        Uri.parse(asset.url),
        mode: LaunchMode.externalApplication,
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
    required this.hasOriginal,
    required this.onOpen,
  });
  final GuidelinePublication publication;
  final bool hasOriginal;
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
            FilledButton.icon(
              onPressed: hasOriginal ? onOpen : null,
              icon: const Icon(LucideIcons.externalLink),
              label: Text(
                hasOriginal ? 'Open original document' : 'Original unavailable',
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
