import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../data/models/guideline.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/small_chip.dart';

/// A beautiful card widget for displaying guideline information
class GuidelineCard extends StatelessWidget {
  /// The guideline data to display
  final Guideline guideline;

  /// Optional callback when the card is tapped
  final VoidCallback? onTap;

  /// Whether to show expanded details by default
  final bool showExpanded;

  const GuidelineCard({
    super.key,
    required this.guideline,
    this.onTap,
    this.showExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with condition name and priority
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      guideline.displayName,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  AppSpacing.sm.gap,
                  // Priority indicator
                  _buildPriorityChip(context),
                ],
              ),

              AppSpacing.sm.gap,

              // ICD-10 code if available
              if (guideline.hasIcd10Code) ...[
                Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 16,
                      color: context.theme.colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.xs.gap,
                    Text(
                      'ICD-10: ${guideline.icd10Code}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                AppSpacing.sm.gap,
              ],

              // Short description from definition
              if (guideline.hasDefinition) ...[
                Text(
                  guideline.shortDescription,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.theme.colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.sm.gap,
              ],

              // Target population and healthcare level
              if (guideline.hasTargetPopulation ||
                  guideline.healthcareLevelRequired.isNotEmpty) ...[
                Row(
                  children: [
                    if (guideline.hasTargetPopulation) ...[
                      Icon(
                        LucideIcons.users,
                        size: 16,
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                      AppSpacing.xs.gap,
                      Expanded(
                        child: Text(
                          guideline.targetPopulation,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (guideline.hasTargetPopulation &&
                        guideline.healthcareLevelRequired.isNotEmpty)
                      AppSpacing.sm.gap,
                    if (guideline.healthcareLevelRequired.isNotEmpty) ...[
                      Icon(
                        LucideIcons.building2,
                        size: 16,
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                      AppSpacing.xs.gap,
                      Text(
                        guideline.healthcareLevelEnum.shortName,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.sm.gap,
              ],

              // Primary medication if available
              if (guideline.hasPrimaryMedication) ...[
                Row(
                  children: [
                    Icon(
                      LucideIcons.pill,
                      size: 16,
                      color: context.theme.colorScheme.tertiary,
                    ),
                    AppSpacing.xs.gap,
                    Expanded(
                      child: Text(
                        guideline.medicationPrimary,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.sm.gap,
              ],

              // Categories and tags section
              if (guideline.hasCategories || guideline.hasTags) ...[
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    // Category chips
                    ...guideline.categories.map(
                      (category) => SmallChip(
                        label: category.displayName,
                        backgroundColor:
                            context.theme.colorScheme.primaryContainer,
                        textColor: context.theme.colorScheme.onPrimaryContainer,
                        icon: LucideIcons.folder,
                      ),
                    ),

                    // Tag chips
                    ...guideline.tags.map(
                      (tag) => SmallChip(
                        label: tag.displayName,
                        backgroundColor:
                            context.theme.colorScheme.surfaceContainerHigh,
                        textColor: context.theme.colorScheme.onSurface,
                        icon: LucideIcons.tag,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build priority indicator chip
  Widget _buildPriorityChip(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (guideline.priorityLevel) {
      case GuidelinePriority.critical:
        backgroundColor = context.theme.colorScheme.errorContainer;
        textColor = context.theme.colorScheme.onErrorContainer;
        icon = LucideIcons.triangleAlert;
        break;
      case GuidelinePriority.high:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange.shade800;
        icon = LucideIcons.circleAlert;
        break;
      case GuidelinePriority.medium:
        backgroundColor = context.theme.colorScheme.secondaryContainer;
        textColor = context.theme.colorScheme.onSecondaryContainer;
        icon = LucideIcons.info;
        break;
      case GuidelinePriority.low:
        backgroundColor = context.theme.colorScheme.surfaceContainerHigh;
        textColor = context.theme.colorScheme.onSurface;
        icon = LucideIcons.minus;
        break;
    }

    return SmallChip(
      label: guideline.priorityLevel.label,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
    );
  }
}
