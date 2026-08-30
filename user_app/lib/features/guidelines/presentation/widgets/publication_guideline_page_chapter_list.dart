part of '../screens/publication_guideline_page.dart';

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
