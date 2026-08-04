import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import '../utils/app_spacing.dart';

/// A small chip widget for displaying information with icon and label
class SmallChip extends StatelessWidget {
  /// The text label to display
  final String label;

  /// The icon to display before the label
  final IconData icon;

  /// The background color of the chip
  final Color backgroundColor;

  /// Optional text color override
  final Color? textColor;

  /// Optional icon color override
  final Color? iconColor;

  const SmallChip({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? context.theme.colorScheme.onSurface;
    final effectiveIconColor = iconColor ?? context.theme.colorScheme.onSurface;

    return Card.filled(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: effectiveIconColor),
            AppSpacing.hGapXs,
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: effectiveTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
