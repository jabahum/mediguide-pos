import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../data/models/models.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/custom_chip.dart';

class GuidelineHeader extends StatelessWidget {
  final Guideline guideline;

  const GuidelineHeader({super.key, required this.guideline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          guideline.conditionName,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (guideline.hasIcd10Code) ...[
          AppSpacing.gapXs,
          Text(
            guideline.icd10Code,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (guideline.hasTargetPopulation ||
            guideline.healthcareLevelRequired.isNotEmpty) ...[
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (guideline.hasTargetPopulation)
                CustomChip(
                  icon: LucideIcons.users,
                  label: guideline.targetPopulation,
                  color: context.theme.colorScheme.primary,
                ),
              if (guideline.healthcareLevelRequired.isNotEmpty)
                CustomChip(
                  icon: LucideIcons.building,
                  label: guideline.healthcareLevelEnum.shortName,
                  color: context.theme.colorScheme.secondary,
                ),
            ],
          ),
        ],
        AppSpacing.gapMd,
        CustomChip(
          icon: LucideIcons.flag,
          label: '${guideline.priorityLevel.label} Priority',
          color: _getPriorityColor(context, guideline.priorityLevel),
        ),
      ],
    );
  }

  Color _getPriorityColor(BuildContext context, GuidelinePriority priority) {
    switch (priority) {
      case GuidelinePriority.critical:
        return context.theme.colorScheme.error;
      case GuidelinePriority.high:
        return Colors.orange;
      case GuidelinePriority.medium:
        return context.theme.colorScheme.primary;
      case GuidelinePriority.low:
        return Colors.grey;
    }
  }
}
