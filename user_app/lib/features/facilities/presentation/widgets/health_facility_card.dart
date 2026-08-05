import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/features/facilities/data/models/health_facility.dart';
import 'package:user_app/core/constants/app_spacing.dart';

/// Clean list tile for health facility items — icon badge, name, level, ownership, chevron.
class HealthFacilityCard extends StatelessWidget {
  final HealthFacility facility;
  final VoidCallback? onTap;
  final bool showDivider;

  const HealthFacilityCard({
    super.key,
    required this.facility,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

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
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.building2,
                    size: 22,
                    color: cs.primary,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility.name,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (facility.facilityLevelName.isNotEmpty)
                            facility.facilityLevelName,
                          facility.ownershipDisplay,
                        ].join(' · '),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (facility.parishName.isNotEmpty ||
                          facility.subcountyName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (facility.parishName.isNotEmpty)
                              facility.parishName,
                            if (facility.subcountyName.isNotEmpty)
                              facility.subcountyName,
                          ].join(', '),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpacing.md + 44 + AppSpacing.md,
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}
