import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A smart filter button that adapts based on filter state.
///
/// Improvements over original:
/// - Shows filter icon when active, search when inactive
/// - Optional badge for active filter count
/// - Optional reset button
/// - No dependency on a feature state implementation (more reusable)
class FilterButton extends StatelessWidget {
  /// Whether filters are active (reactive via builder or Obx outside)
  final bool hasActiveFilters;

  /// Optional number of active filters (shows badge if > 0)
  final int activeFilterCount;

  /// Callback when main button is pressed
  final VoidCallback onPressed;

  /// Optional reset callback
  final VoidCallback? onReset;

  /// Tooltip text
  final String? tooltip;

  const FilterButton({
    super.key,
    required this.hasActiveFilters,
    required this.onPressed,
    this.activeFilterCount = 0,
    this.onReset,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// MAIN FILTER BUTTON
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip:
                  tooltip ??
                  (hasActiveFilters ? 'Filters active' : 'Search / Filter'),
              icon: Icon(
                hasActiveFilters ? LucideIcons.search : LucideIcons.search,
                color: hasActiveFilters ? colorScheme.primary : null,
              ),
              onPressed: onPressed,
            ),

            /// BADGE (optional)
            if (activeFilterCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    activeFilterCount > 9 ? '9+' : activeFilterCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),

        /// RESET BUTTON (only when active)
        if (hasActiveFilters && onReset != null)
          IconButton(
            icon: Icon(LucideIcons.x, color: colorScheme.error),
            tooltip: 'Clear filters',
            onPressed: onReset,
          ),
      ],
    );
  }
}
