part of '../screens/publication_guideline_page.dart';

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
