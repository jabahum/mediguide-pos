import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:gap/gap.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/constants/app_spacing.dart';

class MyNotificationCard extends StatelessWidget {
  final MyNotification notification;
  final VoidCallback? onTap;

  const MyNotificationCard({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _getTypeColor(context), width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPriorityChip(context),
                    const Spacer(),
                    Text(
                      notification.formattedDate,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Text(
                  notification.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(AppSpacing.xs),
                Text(
                  notification.message,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    _buildTypeChip(context),
                    if (notification.isGeneralNotification) ...[
                      const Gap(AppSpacing.xs),
                      _buildGeneralBadge(context),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context) {
    final color = _getPriorityColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        notification.priority.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final color = _getTypeColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        notification.type.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGeneralBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'GENERAL',
        style: context.textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getTypeColor(BuildContext context) {
    switch (notification.type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Theme.of(context).colorScheme.error;
      case 'info':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getPriorityColor(BuildContext context) {
    switch (notification.priority) {
      case 'urgent':
        return Theme.of(context).colorScheme.error;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Theme.of(context).colorScheme.primary;
      case 'low':
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }
}
