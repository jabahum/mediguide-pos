import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/l10n/app_translations.dart';

/// A reusable header widget for home page sections
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Row(
      children: [
        // Icon if provided
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          AppSpacing.sm.gap,
        ],

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    if (onSeeAll == null) return heading;
    final action = TextButton(
      onPressed: onSeeAll,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppTranslationKey.seeAll,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
        if (constraints.maxWidth < 360 || largeText) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            action,
          ],
        );
      },
    );
  }
}

/// Specialized section headers for different home page sections
class SectionHeaders {
  /// Welcome header with User greeting
  static Widget welcome({required String userName, required String userRole}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                userName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (userRole.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    userRole,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Quick actions section header
  static Widget quickActions({VoidCallback? onSeeAll}) {
    return SectionHeader(
      title: 'Quick Actions',
      subtitle: 'Access essential features',
      icon: LucideIcons.zap,
      onSeeAll: onSeeAll,
    );
  }

  /// Continue reading section header
  static Widget continueReading({VoidCallback? onSeeAll}) {
    return SectionHeader(
      title: 'Continue Reading',
      subtitle: 'Resume where you left off',
      icon: LucideIcons.bookOpen,
      onSeeAll: onSeeAll,
    );
  }

  /// Medical news section header
  static Widget medicalNews({VoidCallback? onSeeAll}) {
    return SectionHeader(
      title: 'Medical News',
      subtitle: 'Latest health updates',
      icon: LucideIcons.newspaper,
      onSeeAll: onSeeAll,
    );
  }

  /// Training section header
  static Widget training({VoidCallback? onSeeAll}) {
    return SectionHeader(
      title: 'Training & Certification',
      subtitle: 'Your learning progress',
      icon: LucideIcons.graduationCap,
      onSeeAll: onSeeAll,
    );
  }
}
