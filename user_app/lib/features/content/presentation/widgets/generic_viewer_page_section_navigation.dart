part of '../screens/generic_viewer_page.dart';

class _SectionNavigation extends StatelessWidget {
  const _SectionNavigation({required this.sections, required this.onSelected});

  final List<GenericPageSection> sections;
  final ValueChanged<GenericPageSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          final section = sections[index];

          return ActionChip(
            avatar: const Icon(LucideIcons.listTree, size: 15),
            label: Text(
              section.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () {
              onSelected(section);
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// PAGE DESCRIPTION
// ===========================================================================
