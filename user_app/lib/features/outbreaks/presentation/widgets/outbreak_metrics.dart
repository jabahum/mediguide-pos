import 'package:flutter/material.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';

class OutbreakMetricGrid extends StatelessWidget {
  const OutbreakMetricGrid({super.key, required this.metrics});

  final List<OutbreakMetric> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 600
          ? 3
          : constraints.maxWidth < 340
          ? 1
          : 2;
      final itemWidth =
          (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: itemWidth,
              child: OutbreakMetricCard(metric: metric),
            ),
        ],
      );
    },
  );
}

class OutbreakMetricCard extends StatelessWidget {
  const OutbreakMetricCard({super.key, required this.metric});

  final OutbreakMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '${metric.label}: ${metric.value} ${metric.unit}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${metric.value}${metric.unit.trim().isEmpty ? '' : ' ${metric.unit}'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              metric.label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
