part of '../screens/tree_selector_page.dart';

class _SelectorInfoCard extends StatelessWidget {
  const _SelectorInfoCard({required this.allowParentSelection});

  final bool allowParentSelection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.listTree,
            size: 18,
            color: colors.onSecondaryContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              allowParentSelection
                  ? 'Tap a row to open or select it. Parent groups may also be selected when available.'
                  : 'Tap a row to select it. Expand groups to browse deeper levels.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TREE SURFACE
// ===========================================================================
