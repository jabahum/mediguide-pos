part of '../screens/home_page.dart';

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.compact});

  final _HomeQuickAction action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '${action.title}. ${action.subtitle}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            action.onTap();
          },
          child: Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(action.icon, color: colors.primary, size: 20),
                ),

                const SizedBox(height: 7),

                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // On wider 2-column layouts we have enough room
                // to show the description as well.
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    action.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// CONTINUE READING
/// ===========================================================================
