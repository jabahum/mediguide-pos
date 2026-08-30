part of '../screens/read_guideline_page.dart';

class _SectionNavigationBar extends StatelessWidget {
  const _SectionNavigationBar({
    required this.sections,
    required this.selectedField,
    required this.onSelected,
  });

  final List<GuidelineSection> sections;

  final String? selectedField;

  final ValueChanged<GuidelineSection> onSelected;

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

          final selected = section.fieldName == selectedField;

          return ChoiceChip(
            selected: selected,
            label: Text(
              section.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onSelected: (_) {
              onSelected(section);
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// SECTION ANCHOR
// ===========================================================================
