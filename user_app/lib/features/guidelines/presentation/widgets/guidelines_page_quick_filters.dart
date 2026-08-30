part of '../screens/guidelines_page.dart';

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({
    required this.hasPermanentFilter,
    required this.hasActiveFilters,
    required this.showHighPriorityOnly,
    required this.isEmergencyRoute,
    required this.targetPopulation,
    required this.onShowAll,
    required this.onToggleHighPriority,
    required this.onEmergency,
    required this.onTargetPopulation,
  });

  final bool hasPermanentFilter;
  final bool hasActiveFilters;
  final bool showHighPriorityOnly;
  final bool isEmergencyRoute;
  final String targetPopulation;

  final VoidCallback onShowAll;
  final VoidCallback onToggleHighPriority;
  final VoidCallback onEmergency;
  final ValueChanged<String> onTargetPopulation;

  @override
  Widget build(BuildContext context) {
    final normalizedPopulation = targetPopulation.toLowerCase();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: LucideIcons.library,
            selected: !hasPermanentFilter && !hasActiveFilters,
            onTap: onShowAll,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'High Priority',
            icon: LucideIcons.triangleAlert,
            selected: showHighPriorityOnly,
            onTap: onToggleHighPriority,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Emergency',
            icon: LucideIcons.siren,
            selected: isEmergencyRoute,
            onTap: onEmergency,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Children',
            icon: LucideIcons.baby,
            selected: normalizedPopulation.contains('children'),
            onTap: () {
              onTargetPopulation(
                normalizedPopulation.contains('children') ? '' : 'Children',
              );
            },
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Adults',
            icon: LucideIcons.user,
            selected: normalizedPopulation.contains('adult'),
            onTap: () {
              onTargetPopulation(
                normalizedPopulation.contains('adult') ? '' : 'Adults',
              );
            },
          ),
        ],
      ),
    );
  }
}
