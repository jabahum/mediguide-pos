import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/extensions.dart';

/// A compact horizontal scroll chip for featured tools on the home page.
/// Fixed width, icon + title + type badge — fits nicely in a horizontal list.
class FeaturedCalculatorChip extends StatelessWidget {
  final Calculator calculator;
  final VoidCallback? onTap;

  const FeaturedCalculatorChip({
    super.key,
    required this.calculator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final typeColor = _typeColor(context, calculator.type);
    final iconColor = calculator.color.toColorOrNull() ?? typeColor;
    final bgColor =
        calculator.backgroundColor.toColorOrNull()?.withValues(alpha: 0.12) ??
        iconColor.withValues(alpha: 0.1);

    return SizedBox(
      width: 160,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh : cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(
                  alpha: isDark ? 0.15 : 0.25,
                ),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcon(calculator.type),
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  AppSpacing.gapSm,
                  // Title
                  Text(
                    calculator.name,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Type label
                  Text(
                    calculator.typeDisplayName,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(CalculatorType type) => switch (type) {
    CalculatorType.calculator => LucideIcons.calculator,
    CalculatorType.decisionTool => LucideIcons.gitBranch,
    CalculatorType.checklist => LucideIcons.listChecks,
  };

  Color _typeColor(BuildContext context, CalculatorType type) => switch (type) {
    CalculatorType.calculator => context.theme.colorScheme.primary,
    CalculatorType.decisionTool => context.theme.colorScheme.tertiary,
    CalculatorType.checklist => context.theme.colorScheme.secondary,
  };
}
