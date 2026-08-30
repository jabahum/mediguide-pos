part of '../screens/home_page.dart';

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({
    required this.greeting,
    required this.userName,
    required this.professionalContext,
    required this.notificationUnreadCount,
    required this.onNotifications,
  });

  final String greeting;
  final String userName;
  final String professionalContext;
  final int notificationUnreadCount;
  final VoidCallback onNotifications;

  @override
  Size get preferredSize =>
      Size.fromHeight(professionalContext.isEmpty ? 76 : 94);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: AppSpacing.md,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),

          if (professionalContext.isNotEmpty) ...[
            const SizedBox(height: 1),

            Text(
              professionalContext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: notificationUnreadCount > 0,
              label: Text(
                notificationUnreadCount > 99
                    ? '99+'
                    : '$notificationUnreadCount',
              ),
              child: const Icon(LucideIcons.bell),
            ),
          ),
        ),
      ],
    );
  }
}

/// ===========================================================================
/// SEARCH
/// ===========================================================================
