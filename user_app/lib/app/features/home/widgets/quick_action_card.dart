import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/glass_card.dart';

/// =======================
/// QUICK ACTION CARD
/// =======================
class QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isEnabled;
  final bool useSolidBackground;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.textColor,
    this.isEnabled = true,
    this.useSolidBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final baseTextColor = textColor ?? theme.colorScheme.onSurface;
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    final disabled = !isEnabled || onTap == null;

    final padding = EdgeInsets.symmetric(
      horizontal: Responsive.horizontalPadding(context) * 0.75,
      vertical: Responsive.doubleValue(
        context,
        mobile: AppSpacing.xs,
        tablet: AppSpacing.sm,
        desktop: AppSpacing.sm,
      ),
    );

    Widget content() {
      return Row(
        children: [
          _IconBox(icon: icon, color: effectiveIconColor, enabled: !disabled),
          AppSpacing.sm.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.fontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    color: disabled
                        ? baseTextColor.withValues(alpha: 0.4)
                        : baseTextColor,
                  ),
                ),
                AppSpacing.xs.gap,
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: Responsive.fontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    color: disabled
                        ? baseTextColor.withValues(alpha: 0.3)
                        : baseTextColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final child = Padding(padding: padding, child: content());

    final decoratedChild = useSolidBackground
        ? Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          )
        : GlassCard.compact(
            baseColor: backgroundColor ?? theme.colorScheme.primaryContainer,
            padding: EdgeInsets.zero,
            child: child,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled ? null : onTap,
        child: Opacity(opacity: disabled ? 0.6 : 1, child: decoratedChild),
      ),
    );
  }
}

/// =======================
/// ICON BOX
/// =======================
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;

  const _IconBox({
    required this.icon,
    required this.color,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: Responsive.iconSize(context, mobile: 20, tablet: 22, desktop: 24),
        color: enabled ? color : color.withValues(alpha: 0.4),
      ),
    );
  }
}

/// =======================
/// QUICK ACTION FACTORY
/// =======================
class QuickActionCards {
  static Widget consultant({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return QuickActionCard(
      title: title,
      subtitle: subtitle,
      icon: LucideIcons.messageCircle,
      onTap: onTap,
      isEnabled: isEnabled,
    );
  }

  static Widget healthInfrastructure({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return QuickActionCard(
      title: title,
      subtitle: subtitle,
      icon: LucideIcons.mapPin,
      onTap: onTap,
      isEnabled: isEnabled,
    );
  }

  static Widget emergencyContacts({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return QuickActionCard(
      title: title,
      subtitle: subtitle,
      icon: LucideIcons.phone,
      onTap: onTap,
      isEnabled: isEnabled,
    );
  }

  static Widget drugIndex({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return QuickActionCard(
      title: title,
      subtitle: subtitle,
      icon: LucideIcons.pill,
      onTap: onTap,
      isEnabled: isEnabled,
    );
  }

  /// =======================
  /// NEW: GUIDELINE TILE
  /// =======================
  static Widget guidelineTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isEnabled = true,
  }) {
    return QuickActionCard(
      title: title,
      subtitle: subtitle,
      icon: LucideIcons.bookOpen,
      onTap: onTap,
      isEnabled: isEnabled,
      iconColor: Colors.white,
      textColor: Colors.white,
      backgroundColor: color,
      useSolidBackground: true,
    );
  }
}
