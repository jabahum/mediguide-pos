part of '../screens/help_center_page.dart';

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.filters,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<_TicketStatusFilter> filters;
  final String selectedValue;
  final ValueChanged<String> onChanged;

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

          final selected = selectedValue == filter.value;

          return _StatusFilterChip(
            label: filter.label,
            icon: filter.icon,
            selected: selected,
            onTap: () {
              if (selected) {
                return;
              }

              onChanged(filter.value);
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// STATUS FILTER CHIP
// ===========================================================================
