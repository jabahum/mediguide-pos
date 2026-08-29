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

class _ClinicalCareGrid extends StatelessWidget {
  const _ClinicalCareGrid({required this.outbreak, required this.documents});

  final PublicOutbreak outbreak;
  final List<PublicOutbreakDocument> documents;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          'Evidence-based clinical management for ${outbreak.diseaseType.isEmpty ? outbreak.title : outbreak.diseaseType}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        AppSpacing.gapLg,
        for (final section in _clinicalCareSections) ...[
          _ClinicalSectionCard(
            section: section,
            document: _documentForKinds(documents, section.documentKinds),
          ),
          AppSpacing.gapSm,
        ],
      ],
    );
  }
}

class _ClinicalSectionCard extends StatelessWidget {
  const _ClinicalSectionCard({required this.section, required this.document});

  final _ClinicalCareSection section;
  final PublicOutbreakDocument? document;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: document == null
            ? null
            : () => context.push(
                AppRoutes.outbreakDocument(document!.outbreakId, document!.id),
                extra: document,
              ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClinicalIconTile(icon: section.icon),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document == null
                          ? 'No published guidance is currently available'
                          : section.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                document == null
                    ? LucideIcons.circleAlert
                    : LucideIcons.chevronRight,
                size: 19,
                color: document == null
                    ? colors.outline
                    : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalCareSection {
  const _ClinicalCareSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.documentKinds,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> documentKinds;
}

const _clinicalCareSections = <_ClinicalCareSection>[
  _ClinicalCareSection(
    title: 'Case Definition',
    subtitle: 'Who is a suspected case?',
    icon: LucideIcons.userRound,
    documentKinds: ['case_definition'],
  ),
  _ClinicalCareSection(
    title: 'Screening & Triage',
    subtitle: 'Identify and prioritise cases',
    icon: LucideIcons.listChecks,
    documentKinds: ['surveillance_protocol', 'checklist'],
  ),
  _ClinicalCareSection(
    title: 'Isolation',
    subtitle: 'Isolation and cohorting',
    icon: LucideIcons.shield,
    documentKinds: ['ipc_protocol'],
  ),
  _ClinicalCareSection(
    title: 'Clinical Management',
    subtitle: 'Treatment and supportive care',
    icon: LucideIcons.stethoscope,
    documentKinds: ['treatment_protocol', 'sop'],
  ),
  _ClinicalCareSection(
    title: 'Discharge Criteria',
    subtitle: 'When to discharge a patient',
    icon: LucideIcons.logOut,
    documentKinds: ['referral_protocol'],
  ),
  _ClinicalCareSection(
    title: 'Follow-up & Monitoring',
    subtitle: 'Post-discharge monitoring',
    icon: LucideIcons.activity,
    documentKinds: ['contact_tracing_guide'],
  ),
];

PublicOutbreakDocument? _documentForKinds(
  List<PublicOutbreakDocument> documents,
  List<String> kinds,
) {
  for (final kind in kinds) {
    for (final document in documents) {
      if (document.documentKind == kind) return document;
    }
  }
  return null;
}

String _sectionTitle(String sectionId) => switch (sectionId) {
  'clinical-care' => 'Clinical Care',
  _ => 'Outbreak guidance',
};
