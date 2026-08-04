import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/themes/app_text_theme.dart';
import '../../../data/models/models.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/extensions.dart';

/// Clean list tile for calculator/tool items — MDCalc-style.
/// No cards, just icon badge + text + chevron with divider.
class CalculatorTile extends StatelessWidget {
  final Calculator calculator;
  final VoidCallback? onTap;
  final bool showDivider;

  const CalculatorTile({
    super.key,
    required this.calculator,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(context, calculator.type);
    final iconColor = calculator.color.toColorOrNull() ?? typeColor;
    final bgColor =
        calculator.backgroundColor.toColorOrNull()?.withValues(alpha: 0.12) ??
        iconColor.withValues(alpha: 0.1);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(calculator.type),
                    size: 22,
                    color: iconColor,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        calculator.name,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (calculator.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          calculator.description,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        "${calculator.typeDisplayName} • v${calculator.version}",
                        style: context.textTheme.labelSmall?.w500.copyWith(
                          color: typeColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpacing.md + 44 + AppSpacing.md,
            color: context.theme.colorScheme.outlineVariant.withValues(
              alpha: 0.4,
            ),
          ),
      ],
    );
  }

  IconData _getTypeIcon(CalculatorType type) => switch (type) {
    CalculatorType.calculator => LucideIcons.calculator,
    CalculatorType.decisionTool => LucideIcons.gitBranch,
    CalculatorType.checklist => LucideIcons.listChecks,
  };

  Color _getTypeColor(BuildContext context, CalculatorType type) =>
      switch (type) {
        CalculatorType.calculator => context.theme.colorScheme.primary,
        CalculatorType.decisionTool => context.theme.colorScheme.tertiary,
        CalculatorType.checklist => context.theme.colorScheme.secondary,
      };
}
