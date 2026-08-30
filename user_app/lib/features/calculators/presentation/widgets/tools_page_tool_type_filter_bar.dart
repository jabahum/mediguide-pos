part of '../screens/tools_page.dart';

class _ToolTypeFilterBar extends StatelessWidget {
  const _ToolTypeFilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<_ToolTypeFilter> filters;

  final int selectedIndex;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => AppSpacing.sm.gap,
        itemBuilder: (context, index) {
          final filter = filters[index];

          final selected = selectedIndex == filter.tabIndex;

          return _ToolTypeChip(
            label: filter.label,
            icon: filter.icon,
            selected: selected,
            onTap: () {
              if (selected) {
                return;
              }

              onChanged(filter.tabIndex);
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// TOOL FILTER CHIP
// ============================================================================
