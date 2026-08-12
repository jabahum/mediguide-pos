import 'package:flutter/material.dart';
import 'package:user_app/core/constants/app_dimensions.dart';

enum AppStatusTone { neutral, information, success, warning, critical }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final IconData icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (tone) {
      AppStatusTone.information => colors.primary,
      AppStatusTone.success => colors.tertiary,
      AppStatusTone.warning => colors.secondary,
      AppStatusTone.critical => colors.error,
      AppStatusTone.neutral => colors.onSurfaceVariant,
    };
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppDimensions.iconSmall, color: color),
              const SizedBox(width: 6),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}
