import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import '../utils/app_spacing.dart';

/// A reusable section header widget for profile/settings pages
class ProfileSectionHeader extends StatelessWidget {
  /// The title text to display
  final String title;

  /// Optional custom text style
  final TextStyle? textStyle;

  /// Optional custom color
  final Color? color;

  /// Custom padding around the text
  final EdgeInsetsGeometry? padding;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    this.textStyle,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        title,
        style:
            textStyle ??
            context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? context.theme.colorScheme.primary,
            ),
      ),
    );
  }
}
