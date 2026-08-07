import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/responsive.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.actionIcon = LucideIcons.refreshCw,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String description;

  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  final Color? iconColor;
  final Color? iconBackgroundColor;

  factory EmptyState.noData({
    Key? key,
    String? title,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      icon: LucideIcons.folderOpen,
      title: title ?? 'No Data Found',
      description: description ?? 'There is no data available at this time.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyState.noResults({
    Key? key,
    String? title,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      icon: LucideIcons.searchX,
      title: title ?? 'No Results Found',
      description: description ?? 'Try adjusting your search or filters.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyState.error({
    Key? key,
    String? title,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      icon: LucideIcons.triangleAlert,
      title: title ?? 'Something Went Wrong',
      description: description ?? 'An error occurred while loading data.',
      actionLabel: actionLabel,
      onAction: onAction,
      actionIcon: LucideIcons.refreshCw,
    );
  }

  factory EmptyState.comingSoon({
    Key? key,
    String? title,
    String? description,
  }) {
    return EmptyState(
      key: key,
      icon: LucideIcons.clock,
      title: title ?? 'Coming Soon',
      description: description ?? 'This feature will be available soon.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final textTheme = context.textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.responsiveHorizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor ??
                      colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 52,
                  color: iconColor ?? colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
