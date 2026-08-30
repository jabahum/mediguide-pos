part of '../screens/global_search_page.dart';

class _SearchAvailabilityBadge extends StatelessWidget {
  const _SearchAvailabilityBadge({required this.offline, required this.stale});

  final bool offline;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          offline ? LucideIcons.cloudOff : LucideIcons.clock3,
          size: 13,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          offline
              ? (stale
                    ? 'Offline cached result · may be stale'
                    : 'Offline cached result')
              : 'Cached result · verify online',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
