import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/responsive.dart';

/// A reusable empty state widget that displays when no content is available
///
/// Provides consistent empty state UI across the app with:
/// - Large icon with themed background
/// - Title and description text
/// - Optional action button
/// - Responsive design
/// - Theme-aware styling
class EmptyState extends StatelessWidget {
  /// The icon to display in the empty state
  final IconData icon;

  /// The main title text
  final String title;

  /// The description text explaining the empty state
  final String description;

  /// Optional action button text
  final String? actionLabel;

  /// Callback for the action button
  final VoidCallback? onAction;

  /// Icon color (defaults to onSurfaceVariant)
  final Color? iconColor;

  /// Icon background color (defaults to surfaceContainerHighest)
  final Color? iconBackgroundColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBackgroundColor,
  });

  /// Factory constructor for "no data found" scenarios
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

  /// Factory constructor for "no results" scenarios
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

  /// Factory constructor for "error" scenarios
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
      actionLabel: actionLabel ?? 'Try Again',
      onAction: onAction,
    );
  }

  /// Factory constructor for "coming soon" scenarios
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsiveHorizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large circular icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color:
                    iconBackgroundColor ??
                    context.theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 60,
                color: iconColor ?? context.theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // Optional action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
