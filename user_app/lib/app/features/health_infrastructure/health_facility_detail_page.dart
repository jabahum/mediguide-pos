import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/models.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/section_group.dart';

class HealthFacilityDetailPage extends StatelessWidget {
  const HealthFacilityDetailPage({super.key, this.facility});

  final HealthFacility? facility;

  @override
  Widget build(BuildContext context) {
    final facility = this.facility;
    if (facility == null) {
      return const _InvalidFacilityState();
    }

    return Scaffold(
      appBar: AppBar(title: Text(facility.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _FacilityHeader(facility: facility),

            AppSpacing.gapLg,

            if (_hasLocationData(facility)) ...[
              SectionGroup(
                title: 'Location',
                items: [
                  if (facility.regionName.trim().isNotEmpty)
                    _DetailRow(label: 'Region', value: facility.regionName),
                  if (facility.districtName.trim().isNotEmpty)
                    _DetailRow(label: 'District', value: facility.districtName),
                  if (facility.countyName.trim().isNotEmpty)
                    _DetailRow(label: 'County', value: facility.countyName),
                  if (facility.subcountyName.trim().isNotEmpty)
                    _DetailRow(
                      label: 'Sub-county',
                      value: facility.subcountyName,
                    ),
                  if (facility.parishName.trim().isNotEmpty)
                    _DetailRow(label: 'Parish', value: facility.parishName),
                ],
              ),
              AppSpacing.gapMd,
            ],

            if (_hasFacilityCodes(facility)) ...[
              SectionGroup(
                title: 'Facility Codes',
                items: [
                  if (facility.nhpiCode.trim().isNotEmpty)
                    _DetailRow(
                      label: 'NHPI Code',
                      value: facility.nhpiCode,
                      mono: true,
                    ),
                  if (facility.hsdtCode.trim().isNotEmpty)
                    _DetailRow(
                      label: 'HSDT Code',
                      value: facility.hsdtCode,
                      mono: true,
                    ),
                ],
              ),
              AppSpacing.gapMd,
            ],

            SectionGroup(
              title: 'Administrative Info',
              items: [
                _DetailRow(
                  label: 'Created',
                  value: _formatDate(facility.created),
                ),
                _DetailRow(
                  label: 'Updated',
                  value: _formatDate(facility.updated),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _hasLocationData(HealthFacility facility) {
    return facility.regionName.trim().isNotEmpty ||
        facility.districtName.trim().isNotEmpty ||
        facility.countyName.trim().isNotEmpty ||
        facility.subcountyName.trim().isNotEmpty ||
        facility.parishName.trim().isNotEmpty;
  }

  static bool _hasFacilityCodes(HealthFacility facility) {
    return facility.nhpiCode.trim().isNotEmpty ||
        facility.hsdtCode.trim().isNotEmpty;
  }

  static String _formatDate(String value) {
    if (value.trim().isEmpty) return '—';

    try {
      final date = DateTime.parse(value).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    } catch (_) {
      return value;
    }
  }
}

class _FacilityHeader extends StatelessWidget {
  final HealthFacility facility;

  const _FacilityHeader({required this.facility});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          facility.name,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),

        AppSpacing.gapMd,

        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _InfoChip(
              icon: LucideIcons.building2,
              label: facility.facilityLevelName.trim().isEmpty
                  ? 'Unknown Level'
                  : facility.facilityLevelName,
              color: cs.primary,
            ),
            if (facility.ownershipDisplay.trim().isNotEmpty)
              _InfoChip(
                icon: LucideIcons.users,
                label: facility.ownershipDisplay,
                color: cs.secondary,
              ),
            if (facility.authorityName.trim().isNotEmpty)
              _InfoChip(
                icon: LucideIcons.shield,
                label: facility.authorityName,
                color: cs.tertiary,
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: SelectableText(
              value.trim().isEmpty ? '—' : value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvalidFacilityState extends StatelessWidget {
  const _InvalidFacilityState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          'Invalid facility details.',
          style: context.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
