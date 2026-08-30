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

class _SectionAnchor extends StatelessWidget {
  const _SectionAnchor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(container: true, child: child);
  }
}

// ===========================================================================
// NO STRUCTURED SECTIONS
// ===========================================================================

class _NoStructuredSections extends StatelessWidget {
  const _NoStructuredSections({required this.guideline});

  final Guideline guideline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.bookOpenText,
              color: colors.primary,
              size: 20,
            ),
          ),

          AppSpacing.gapMd,

          Text(
            'No structured sections available',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),

          AppSpacing.gapSm,

          Text(
            'This guideline does not currently contain structured reader sections.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
