part of '../screens/notifications_page.dart';

class _ActiveNotificationFilterChip extends StatelessWidget {
  const _ActiveNotificationFilterChip({
    required this.icon,
    required this.label,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InputChip(
      avatar: Icon(icon, size: 14, color: colors.onSecondaryContainer),
      label: Text(label),
      onDeleted: onClear,
      deleteIcon: const Icon(LucideIcons.x, size: 14),
      backgroundColor: colors.surface.withValues(alpha: 0.65),
      side: BorderSide.none,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ===========================================================================
// CARD SHELL
// ===========================================================================
