import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/section_group.dart';

class HealthFacilityDetailPage extends StatelessWidget {
  const HealthFacilityDetailPage({super.key, this.facility});

  final HealthFacility? facility;

  @override
  Widget build(BuildContext context) {
    final value = facility;

    if (value == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState.noData(
          title: 'Facility unavailable',
          description: 'The facility details could not be found.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(value.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _FacilityHeader(facility: value),

            AppSpacing.gapLg,

            if (_hasLocationData(value)) ...[
              SectionGroup(
                title: 'Location',
                items: [
                  if (_hasText(value.regionName))
                    _DetailRow(label: 'Region', value: value.regionName),
                  if (_hasText(value.districtName))
                    _DetailRow(label: 'District', value: value.districtName),
                  if (_hasText(value.countyName))
                    _DetailRow(label: 'County', value: value.countyName),
                  if (_hasText(value.subcountyName))
                    _DetailRow(label: 'Sub-county', value: value.subcountyName),
                  if (_hasText(value.parishName))
                    _DetailRow(label: 'Parish', value: value.parishName),
                ],
              ),
              AppSpacing.gapMd,
            ],

            if (_hasFacilityCodes(value)) ...[
              SectionGroup(
                title: 'Facility Codes',
                items: [
                  if (_hasText(value.nhpiCode))
                    _DetailRow(
                      label: 'NHPI Code',
                      value: value.nhpiCode,
                      mono: true,
                    ),
                  if (_hasText(value.hsdtCode))
                    _DetailRow(
                      label: 'HSDT Code',
                      value: value.hsdtCode,
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
                  value: _formatDate(value.createdAt),
                ),
                _DetailRow(
                  label: 'Updated',
                  value: _formatDate(value.updatedAt),
                ),
              ],
            ),

            AppSpacing.gapXl,
          ],
        ),
      ),
    );
  }

  static bool _hasText(String? value) {
    return value?.trim().isNotEmpty == true;
  }

  static bool _hasLocationData(HealthFacility facility) {
    return _hasText(facility.regionName) ||
        _hasText(facility.districtName) ||
        _hasText(facility.countyName) ||
        _hasText(facility.subcountyName) ||
        _hasText(facility.parishName);
  }

  static bool _hasFacilityCodes(HealthFacility facility) {
    return _hasText(facility.nhpiCode) || _hasText(facility.hsdtCode);
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }

    final date = value.toLocal();

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _FacilityHeader extends StatelessWidget {
  const _FacilityHeader({required this.facility});

  final HealthFacility facility;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(LucideIcons.building2, color: cs.primary, size: 28),
              ),

              AppSpacing.md.gap,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),

                    if (facility.districtName.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 15,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              facility.districtName,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
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
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

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
  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final displayValue = value.trim().isEmpty ? '—' : value.trim();

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
              displayValue,
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
