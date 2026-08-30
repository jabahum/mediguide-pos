part of '../screens/guest_more_page.dart';

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ListTile(
        onTap: onTap,
        minTileHeight: 68,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),

        // -----------------------------------------------------------
        // ICON
        // -----------------------------------------------------------
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: cs.primary, size: 19),
        ),

        // -----------------------------------------------------------
        // CONTENT
        // -----------------------------------------------------------
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),

        trailing: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ============================================================================
// GUEST ACCESS INFORMATION
// ============================================================================
