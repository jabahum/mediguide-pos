part of '../screens/health_facility_detail_page.dart';

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
