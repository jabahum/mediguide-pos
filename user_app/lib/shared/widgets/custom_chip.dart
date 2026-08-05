import 'package:flutter/material.dart';

/// A reusable custom chip widget with customizable styling
class CustomChip extends StatelessWidget {
  /// The text to display on the chip
  final String label;

  /// The color of the chip border and background tint
  final Color color;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Optional callback when chip is tapped
  final VoidCallback? onTap;

  /// Text style for the label
  final TextStyle? textStyle;

  /// Custom padding for the chip content
  final EdgeInsets? padding;

  /// Custom border radius
  final double borderRadius;

  /// Whether the chip should be compact (smaller padding)
  final bool compact;

  const CustomChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
    this.textStyle,
    this.padding,
    this.borderRadius = 16.0,
    this.compact = false,
  });

  /// Create a compact chip with smaller padding
  const CustomChip.compact({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
    this.textStyle,
    this.padding,
    this.borderRadius = 16.0,
  }) : compact = true;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ??
        (compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6));

    final widget = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 14 : 16, color: color),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            label,
            style:
                textStyle ??
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: compact ? 12 : 14,
                ),
          ),
        ],
      ),
    );

    return onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: widget,
          )
        : widget;
  }
}
