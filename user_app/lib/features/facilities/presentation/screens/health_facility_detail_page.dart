import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/shared/models/models.dart';

part '../widgets/health_facility_detail_page_facility_details_scaffold.dart';
part '../widgets/health_facility_detail_page_facility_summary_card.dart';
part '../widgets/health_facility_detail_page_info_badge.dart';
part '../widgets/health_facility_detail_page_detail_section.dart';
part '../widgets/health_facility_detail_page_detail_item.dart';

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
