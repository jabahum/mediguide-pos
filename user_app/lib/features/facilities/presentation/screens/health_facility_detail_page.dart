import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/shared/models/models.dart';

final healthFacilityDetailsProvider = FutureProvider.autoDispose
    .family<HealthFacility, String>((ref, facilityId) {
      return ref.watch(facilityRepositoryProvider).facility(facilityId);
    });

class HealthFacilityDetailPage extends ConsumerWidget {
  const HealthFacilityDetailPage({super.key, this.facilityId, this.facility});

  final String? facilityId;
  final HealthFacility? facility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialValue = facility;

    if (initialValue != null) {
      return _FacilityDetailsScaffold(facility: initialValue);
    }

    final id = facilityId?.trim() ?? '';

    if (id.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState.noData(
          title: 'Facility unavailable',
          description: 'The facility details could not be found.',
        ),
      );
    }

    return ref
        .watch(healthFacilityDetailsProvider(id))
        .when(
          loading: () => Scaffold(
            appBar: AppBar(),
            body: const AppLoadingView(message: 'Loading facility details...'),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: AppErrorView(
              error: error,
              title: 'Unable to load facility',
              message:
                  'The facility details could not be loaded. '
                  'Check your connection and try again.',
              onRetry: () {
                ref.invalidate(healthFacilityDetailsProvider(id));
              },
            ),
          ),
          data: (value) {
            return _FacilityDetailsScaffold(facility: value);
          },
        );
  }
}

class _FacilityDetailsScaffold extends StatelessWidget {
  const _FacilityDetailsScaffold({required this.facility});

  final HealthFacility facility;

  @override
  Widget build(BuildContext context) {
    final value = facility;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (_hasText(value.facilityLevelName))
              Text(
                value.facilityLevelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          children: [
            // =================================================================
            // SUMMARY
            // =================================================================
            _FacilitySummaryCard(facility: value),

            AppSpacing.gapXl,

            // =================================================================
            // LOCATION
            // =================================================================
            if (_hasLocationData(value)) ...[
              _DetailSection(
                icon: LucideIcons.mapPin,
                title: 'Location',
                description: 'Administrative location of this health facility.',
                rows: [
                  if (_hasText(value.regionName))
                    _DetailItem(label: 'Region', value: value.regionName),
                  if (_hasText(value.districtName))
                    _DetailItem(label: 'District', value: value.districtName),
                  if (_hasText(value.countyName))
                    _DetailItem(label: 'County', value: value.countyName),
                  if (_hasText(value.subcountyName))
                    _DetailItem(
                      label: 'Sub-county',
                      value: value.subcountyName,
                    ),
                  if (_hasText(value.parishName))
                    _DetailItem(label: 'Parish', value: value.parishName),
                ],
              ),

              AppSpacing.gapLg,
            ],

            // =================================================================
            // FACILITY INFORMATION
            // =================================================================
            _DetailSection(
              icon: LucideIcons.hospital,
              title: 'Facility information',
              description: 'Level, ownership and administrative authority.',
              rows: [
                if (_hasText(value.facilityLevelName))
                  _DetailItem(
                    label: 'Facility level',
                    value: value.facilityLevelName,
                  ),
                if (_hasText(value.ownershipDisplay))
                  _DetailItem(
                    label: 'Ownership',
                    value: value.ownershipDisplay,
                  ),
                if (_hasText(value.authorityName))
                  _DetailItem(label: 'Authority', value: value.authorityName),
              ],
            ),

            if (_hasFacilityCodes(value)) ...[
              AppSpacing.gapLg,

              // ===============================================================
              // IDENTIFIERS
              // ===============================================================
              _DetailSection(
                icon: LucideIcons.scanBarcode,
                title: 'Facility identifiers',
                description:
                    'Reference codes used across connected health systems.',
                rows: [
                  if (_hasText(value.nhpiCode))
                    _DetailItem(
                      label: 'NHPI Code',
                      value: value.nhpiCode,
                      mono: true,
                      selectable: true,
                    ),
                  if (_hasText(value.hsdtCode))
                    _DetailItem(
                      label: 'HSDT Code',
                      value: value.hsdtCode,
                      mono: true,
                      selectable: true,
                    ),
                ],
              ),
            ],

            AppSpacing.gapLg,

            // =================================================================
            // RECORD INFORMATION
            // =================================================================
            _DetailSection(
              icon: LucideIcons.clock3,
              title: 'Record information',
              description: 'Metadata for this facility record.',
              rows: [
                _DetailItem(
                  label: 'Created',
                  value: _formatDate(value.createdAt),
                ),
                _DetailItem(
                  label: 'Updated',
                  value: _formatDate(value.updatedAt),
                ),
              ],
            ),
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

// ===========================================================================
// SUMMARY CARD
// ===========================================================================

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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSecondaryContainer),

          const SizedBox(width: 5),

          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// DETAIL SECTION
// ===========================================================================

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<_DetailItem> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: colors.primary),
            ),

            AppSpacing.hGapSm,

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        AppSpacing.gapSm,

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                rows[index],

                if (index < rows.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: colors.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// DETAIL ROW
// ===========================================================================

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    this.mono = false,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final displayValue = value.trim().isEmpty ? '—' : value.trim();

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.35,
      fontFamily: mono ? 'monospace' : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: selectable
                ? SelectableText(displayValue, style: valueStyle)
                : Text(displayValue, style: valueStyle),
          ),
        ],
      ),
    );
  }
}
