part of '../screens/my_library_page.dart';

class _LibraryMenuTile extends StatelessWidget {
  const _LibraryMenuTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final String description;
  final int? count;

  //
  // Required instead of optional.
  //
  // This intentionally prevents accidentally creating a library row
  // that looks tappable but does nothing.
  //
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      leading: _LibraryActionIcon(icon: icon),
      title: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),

          if (count != null)
            Container(
              constraints: const BoxConstraints(minWidth: 26),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 19),
    );
  }
}
