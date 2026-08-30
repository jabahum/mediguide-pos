part of '../screens/publication_guideline_page.dart';

class _BottomIconAction extends StatelessWidget {
  const _BottomIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 20, color: colors.primary),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// READER BOTTOM ACTION
// =============================================================================
