part of '../screens/health_facility_detail_page.dart';

class _FacilitySummaryCard extends StatelessWidget {
  const _FacilitySummaryCard({required this.facility});

  final HealthFacility facility;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final locationParts = <String>[
      if (facility.subcountyName.trim().isNotEmpty)
        facility.subcountyName.trim(),
      if (facility.districtName.trim().isNotEmpty) facility.districtName.trim(),
      if (facility.regionName.trim().isNotEmpty) facility.regionName.trim(),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.hospital,
                  size: 23,
                  color: colors.primary,
                ),
              ),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),

                    if (locationParts.isNotEmpty) ...[
                      const SizedBox(height: 5),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 15,
                            color: colors.onSurfaceVariant,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              locationParts.join(' • '),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.gapMd,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (facility.facilityLevelName.trim().isNotEmpty)
                _InfoBadge(
                  icon: LucideIcons.building2,
                  label: facility.facilityLevelName,
                ),

              if (facility.ownershipDisplay.trim().isNotEmpty)
                _InfoBadge(
                  icon: LucideIcons.users,
                  label: facility.ownershipDisplay,
                ),

              if (facility.authorityName.trim().isNotEmpty)
                _InfoBadge(
                  icon: LucideIcons.shieldCheck,
                  label: facility.authorityName,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// INFO BADGE
// ===========================================================================
