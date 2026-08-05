import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/features/home/data/models/stats_model.dart';

/// Widget displaying application statistics in a card layout
class StatsWidget extends StatelessWidget {
  final StatsModel stats;
  final VoidCallback? onTap;

  const StatsWidget({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.pill,
                label: AppTranslationKey.drugs,
                value: stats.formattedDrugsCount,
                color: context.theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            AppSpacing.md.gap,
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.fileText,
                label: AppTranslationKey.guidelines,
                value: stats.formattedGuidelinesCount,
                color: context.theme.colorScheme.secondary.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            AppSpacing.md.gap,
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.building2,
                label: AppTranslationKey.healthcareFacilities,
                value: stats.formattedHealthcareFacilitiesCount,
                color: context.theme.colorScheme.tertiary.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
        ),

        AppSpacing.xl.gap,

        // Second row with new stats
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.userCheck,
                label: 'Consultants',
                value: stats.formattedConsultantsCount,
                color: context.theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.9,
                ),
              ),
            ),
            AppSpacing.md.gap,
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.calculator,
                label: 'Medical Tools',
                value: stats.formattedPatientsServedCount,
                color: context.theme.colorScheme.outline.withValues(alpha: 0.9),
              ),
            ),
            AppSpacing.md.gap,
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.phone,
                label: 'Emergency Contacts',
                value: stats.formattedEmergencyContactsCount,
                color: context.theme.colorScheme.error.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),

        AppSpacing.xl.gap,

        // Third row with user conversations and FAQs
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.messageCircle,
                label: 'Your Conversations',
                value: stats.formattedUserConversationsCount,
                color: context.theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            AppSpacing.md.gap,
            Expanded(
              child: _buildStatItem(
                context,
                icon: LucideIcons.info,
                label: 'FAQs',
                value: stats.formattedFaqsCount,
                color: context.theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            AppSpacing.md.gap,
            Expanded(child: SizedBox()), // Empty placeholder
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final iconSize = Responsive.iconSize(
      context,
      mobile: 28.0,
      tablet: 32.0,
      desktop: 36.0,
      fourK: 40.0,
    );

    final iconPadding = Responsive.doubleValue(
      context,
      mobile: AppSpacing.sm,
      tablet: AppSpacing.md,
      desktop: AppSpacing.lg,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
          ),
          child: Icon(icon, size: iconSize, color: color),
        ),
        SizedBox(
          height: Responsive.doubleValue(
            context,
            mobile: 6,
            tablet: 8,
            desktop: 10,
          ),
        ),
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface,
            fontSize: Responsive.fontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
          ),
        ),
        SizedBox(
          height: Responsive.doubleValue(
            context,
            mobile: 2,
            tablet: 3,
            desktop: 4,
          ),
        ),
        Flexible(
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.theme.colorScheme.onSurfaceVariant,
              fontSize: Responsive.fontSize(
                context,
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Compact horizontal stats widget for smaller spaces
class CompactStatsWidget extends StatelessWidget {
  final StatsModel stats;
  final VoidCallback? onTap;

  const CompactStatsWidget({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.activity,
              size: 16,
              color: context.theme.colorScheme.primary,
            ),
            AppSpacing.xs.gap,
            Text(
              '${stats.formattedDrugsCount} drugs',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              ' • ',
              style: TextStyle(
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${stats.formattedGuidelinesCount} guidelines',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onTap != null) ...[
              AppSpacing.xs.gap,
              Icon(
                LucideIcons.chevronRight,
                size: 12,
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
