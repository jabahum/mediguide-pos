import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

part '../widgets/outbreak_section_grid_page_clinical_care_grid.dart';
part '../widgets/outbreak_section_grid_page_clinical_section_card.dart';
part '../widgets/outbreak_section_grid_page_clinical_care_section.dart';

class OutbreakSectionGridPage extends ConsumerWidget {
  const OutbreakSectionGridPage({
    super.key,
    required this.outbreakId,
    required this.sectionId,
  });

  final String outbreakId;
  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(publicOutbreakProvider(outbreakId));
    return Scaffold(
      appBar: AppBar(title: Text(_sectionTitle(sectionId))),
      body: detail.when(
        loading: () => const AppLoadingView(
          message: 'Loading published clinical guidance...',
        ),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Clinical guidance unavailable',
          onRetry: () => ref.invalidate(publicOutbreakProvider(outbreakId)),
        ),
        data: (content) => _ClinicalCareGrid(
          outbreak: content.value.outbreak,
          documents: content.value.documents,
        ),
      ),
    );
  }
}
