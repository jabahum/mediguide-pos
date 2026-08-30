part of '../screens/guidelines_indexer_page.dart';

class _QuickFilterChips extends StatelessWidget {
  const _QuickFilterChips({
    required this.filters,
    required this.onReset,
    required this.onLevelChanged,
    required this.onToggleParents,
  });

  final GuidelinesTreeFilter filters;

  final VoidCallback onReset;
  final ValueChanged<int?> onLevelChanged;
  final VoidCallback onToggleParents;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _BrowseChip(
            label: 'All',
            icon: LucideIcons.layers,
            selected: !filters.hasFilters,
            onTap: onReset,
          ),

          AppSpacing.hGapSm,

          _BrowseChip(
            label: 'Top level',
            icon: LucideIcons.folder,
            selected: filters.level == 1,
            onTap: () {
              onLevelChanged(filters.level == 1 ? null : 1);
            },
          ),

          AppSpacing.hGapSm,

          _BrowseChip(
            label: 'Subsections',
            icon: LucideIcons.folderOpen,
            selected: filters.level == 2,
            onTap: () {
              onLevelChanged(filters.level == 2 ? null : 2);
            },
          ),

          AppSpacing.hGapSm,

          _BrowseChip(
            label: 'Parents only',
            icon: LucideIcons.listTree,
            selected: filters.showOnlyParents,
            onTap: onToggleParents,
          ),
        ],
      ),
    );
  }
}
