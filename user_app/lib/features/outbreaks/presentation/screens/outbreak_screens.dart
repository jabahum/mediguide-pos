import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';
import 'package:user_app/shared/widgets/section_header.dart';

final publicOutbreaksProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(outbreakRepositoryProvider).outbreaks(),
);

final publicOutbreakProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(outbreakRepositoryProvider).outbreak(id),
);

final publicSituationReportsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(outbreakRepositoryProvider).reports(),
);

final publicSituationReportProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(outbreakRepositoryProvider).report(id),
);

// ===========================================================================
// OUTBREAK HUB
// ===========================================================================

class OutbreakHubPage extends ConsumerWidget {
  const OutbreakHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outbreaks = ref.watch(publicOutbreaksProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outbreak response hub',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Public emergency updates and response guidance',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Situation reports',
            onPressed: () {
              context.push(AppRoutes.situationReports);
            },
            icon: const Icon(LucideIcons.fileChartColumn),
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: outbreaks.when(
        loading: () =>
            const AppLoadingView(message: 'Loading public outbreak updates...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Public updates unavailable',
          message: 'Outbreak information cannot be loaded right now.',
          onRetry: () {
            ref.invalidate(publicOutbreaksProvider);
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _PublicEmptyState(
              icon: LucideIcons.shieldCheck,
              title: 'No published outbreak updates',
              message:
                  'There are currently no public outbreak records available.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(publicOutbreaksProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              children: [
                const _OutbreakHubIntro(),

                AppSpacing.gapLg,

                const SectionHeader(
                  title: 'Published outbreaks',
                  subtitle: 'Current and historical public response updates',
                  icon: LucideIcons.siren,
                ),

                AppSpacing.gapSm,

                for (final outbreak in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _OutbreakCard(
                      outbreak: outbreak,
                      onTap: () {
                        context.push(AppRoutes.outbreak(outbreak.id));
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// OUTBREAK DETAIL
// ===========================================================================

class OutbreakDetailPage extends ConsumerWidget {
  const OutbreakDetailPage({super.key, required this.outbreakId});

  final String outbreakId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outbreak = ref.watch(publicOutbreakProvider(outbreakId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Response hub'),
        actions: [
          IconButton(
            tooltip: 'Copy outbreak link',
            onPressed: () {
              _copyLink(context, AppRoutes.outbreak(outbreakId));
            },
            icon: const Icon(LucideIcons.share2),
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: outbreak.when(
        loading: () => const AppLoadingView(message: 'Loading response hub...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Response hub unavailable',
          onRetry: () {
            ref.invalidate(publicOutbreakProvider(outbreakId));
          },
        ),
        data: (detail) {
          return _OutbreakDetail(detail: detail);
        },
      ),
    );
  }
}

// ===========================================================================
// SITUATION REPORT LIST
// ===========================================================================

class SituationReportsPage extends ConsumerWidget {
  const SituationReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(publicSituationReportsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Situation reports',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Published outbreak and emergency reports',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: reports.when(
        loading: () =>
            const AppLoadingView(message: 'Loading situation reports...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Situation reports unavailable',
          onRetry: () {
            ref.invalidate(publicSituationReportsProvider);
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _PublicEmptyState(
              icon: LucideIcons.fileText,
              title: 'No published situation reports',
              message: 'Reports will appear here after publication.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(publicSituationReportsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              children: [
                const _SituationReportsIntro(),

                AppSpacing.gapLg,

                for (final report in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SituationReportCard(
                      report: report,
                      onTap: () {
                        context.push(AppRoutes.situationReport(report.id));
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// SITUATION REPORT DETAIL
// ===========================================================================

class SituationReportDetailPage extends ConsumerWidget {
  const SituationReportDetailPage({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(publicSituationReportProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Situation report'),
        actions: [
          IconButton(
            tooltip: 'Copy report link',
            onPressed: () {
              _copyLink(context, AppRoutes.situationReport(reportId));
            },
            icon: const Icon(LucideIcons.share2),
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: report.when(
        loading: () => const AppLoadingView(message: 'Loading report...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Situation report unavailable',
          onRetry: () {
            ref.invalidate(publicSituationReportProvider(reportId));
          },
        ),
        data: (report) {
          return _SituationReportView(report: report);
        },
      ),
    );
  }
}

// ===========================================================================
// HUB INTRO
// ===========================================================================

class _OutbreakHubIntro extends StatelessWidget {
  const _OutbreakHubIntro();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.siren,
              color: colors.onErrorContainer,
              size: 21,
            ),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Review official outbreak updates, response resources and situation reports.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// OUTBREAK CARD
// ===========================================================================

class _OutbreakCard extends StatelessWidget {
  const _OutbreakCard({required this.outbreak, required this.onTap});

  final PublicOutbreak outbreak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final tone = _tone(context, outbreak.visualTone);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tone.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.siren, color: tone, size: 21),
                  ),

                  AppSpacing.hGapMd,

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outbreak.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),

                        if (outbreak.geographicArea.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  outbreak.geographicArea,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  AppSpacing.hGapSm,

                  _StatusChip(status: outbreak.status, color: tone),
                ],
              ),

              if (outbreak.summary.trim().isNotEmpty) ...[
                AppSpacing.gapMd,

                Text(
                  outbreak.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],

              AppSpacing.gapMd,

              Row(
                children: [
                  Icon(
                    LucideIcons.clock3,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      outbreak.lastUpdate == null
                          ? 'Update time unavailable'
                          : 'Updated ${_date(outbreak.lastUpdate)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// OUTBREAK DETAIL
// ===========================================================================

class _OutbreakDetail extends StatelessWidget {
  const _OutbreakDetail({required this.detail});

  final PublicOutbreakDetail detail;

  @override
  Widget build(BuildContext context) {
    final outbreak = detail.outbreak;

    final tone = _tone(context, outbreak.visualTone);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        _OutbreakHero(outbreak: outbreak, color: tone),

        if (outbreak.metrics.isNotEmpty) ...[
          AppSpacing.gapLg,
          const SectionHeader(
            title: 'Current situation',
            subtitle: 'Published response indicators',
            icon: LucideIcons.chartNoAxesColumn,
          ),
          AppSpacing.gapSm,
          _MetricGrid(metrics: outbreak.metrics),
        ],

        if (detail.updates.isNotEmpty) ...[
          AppSpacing.gapLg,

          const SectionHeader(
            title: 'Latest updates',
            subtitle: 'Published outbreak developments',
            icon: LucideIcons.clock3,
          ),

          AppSpacing.gapSm,

          for (final update in detail.updates)
            _UpdateCard(
              title: update.title,
              summary: update.summary,
              date: update.publishedAt,
            ),
        ],

        if (detail.resources.isNotEmpty) ...[
          AppSpacing.gapLg,

          const SectionHeader(
            title: 'Quick resources',
            subtitle: 'Guidance and response material',
            icon: LucideIcons.layoutGrid,
          ),

          AppSpacing.gapSm,

          for (final resource in detail.resources)
            _ResourceTile(
              title: resource.title,
              type: resource.resourceType,
              onTap: () {
                _openExternal(
                  context,
                  resource.url.isNotEmpty ? resource.url : resource.assetUrl,
                );
              },
            ),
        ],

        if (detail.reports.isNotEmpty) ...[
          AppSpacing.gapLg,

          const SectionHeader(
            title: 'Situation reports',
            subtitle: 'Published official reports',
            icon: LucideIcons.fileChartColumn,
          ),

          AppSpacing.gapSm,

          for (final report in detail.reports)
            _SituationReportCard(
              report: report,
              onTap: () {
                context.push(AppRoutes.situationReport(report.id));
              },
            ),
        ],
      ],
    );
  }
}

// ===========================================================================
// OUTBREAK HERO
// ===========================================================================

class _OutbreakHero extends StatelessWidget {
  const _OutbreakHero({required this.outbreak, required this.color});

  final PublicOutbreak outbreak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: outbreak.status, color: color),

              const Spacer(),

              if (outbreak.lastUpdate != null)
                Text(
                  _date(outbreak.lastUpdate),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),

          AppSpacing.gapMd,

          Text(
            outbreak.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),

          if (outbreak.geographicArea.trim().isNotEmpty) ...[
            AppSpacing.gapSm,

            Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    outbreak.geographicArea,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (outbreak.summary.trim().isNotEmpty) ...[
            AppSpacing.gapMd,

            Text(
              outbreak.summary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],

          if (outbreak.sourceOrganization.trim().isNotEmpty) ...[
            AppSpacing.gapMd,

            Row(
              children: [
                Icon(
                  LucideIcons.landmark,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Source: ${outbreak.sourceOrganization}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// UPDATE CARD
// ===========================================================================

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.title,
    required this.summary,
    required this.date,
  });

  final String title;
  final String summary;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.circleDot, color: colors.primary, size: 17),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),

                if (date != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    _date(date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],

                if (summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// RESOURCE TILE
// ===========================================================================

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.title,
    required this.type,
    required this.onTap,
  });

  final String title;
  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const ClinicalIconTile(icon: LucideIcons.externalLink),
        title: Text(title),
        subtitle: type.trim().isEmpty ? null : Text(type),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}

// ===========================================================================
// SITUATION REPORT INTRO
// ===========================================================================

class _SituationReportsIntro extends StatelessWidget {
  const _SituationReportsIntro();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.fileChartColumn,
              color: colors.primary,
              size: 21,
            ),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Text(
              'Situation reports provide official summaries of outbreak status, response actions and key indicators.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SITUATION REPORT CARD
// ===========================================================================

class _SituationReportCard extends StatelessWidget {
  const _SituationReportCard({required this.report, required this.onTap});

  final dynamic report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: const ClinicalIconTile(icon: LucideIcons.fileChartColumn),
        title: Text(report.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            report.geographicArea,
            _date(report.publicationDate),
            report.sourceOrganization,
          ].where((value) => value.toString().trim().isNotEmpty).join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: onTap,
      ),
    );
  }
}

// ===========================================================================
// SITUATION REPORT DETAIL
// ===========================================================================

class _SituationReportView extends StatelessWidget {
  const _SituationReportView({required this.report});

  final PublicSituationReport report;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ClinicalIconTile(icon: LucideIcons.fileChartColumn),

                  AppSpacing.hGapMd,

                  Expanded(
                    child: Text(
                      report.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              AppSpacing.gapMd,

              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (report.geographicArea.trim().isNotEmpty)
                    _MetaChip(
                      icon: LucideIcons.mapPin,
                      label: report.geographicArea,
                    ),

                  if (report.publicationDate != null)
                    _MetaChip(
                      icon: LucideIcons.calendarDays,
                      label: _date(report.publicationDate),
                    ),

                  if (report.sourceOrganization.trim().isNotEmpty)
                    _MetaChip(
                      icon: LucideIcons.landmark,
                      label: report.sourceOrganization,
                    ),
                ],
              ),

              if (report.summary.trim().isNotEmpty) ...[
                AppSpacing.gapMd,

                Text(
                  report.summary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ],
          ),
        ),

        if (report.metrics.isNotEmpty) ...[
          AppSpacing.gapLg,

          const SectionHeader(
            title: 'Key indicators',
            icon: LucideIcons.chartNoAxesColumn,
          ),

          AppSpacing.gapSm,

          _MetricGrid(metrics: report.metrics),
        ],

        if (report.keyHighlights.isNotEmpty) ...[
          AppSpacing.gapLg,

          const SectionHeader(
            title: 'Key highlights',
            icon: LucideIcons.listChecks,
          ),

          AppSpacing.gapSm,

          for (final highlight in report.keyHighlights)
            _HighlightTile(text: highlight),
        ],

        if (report.reportAssetUrl.trim().isNotEmpty) ...[
          AppSpacing.gapLg,

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                context.push(
                  AppRoutes.documentReader,
                  extra: DocumentReaderArgs(
                    title: report.title,
                    source: report.reportAssetUrl,
                  ),
                );
              },
              icon: const Icon(LucideIcons.fileDown),
              label: const Text('View full report'),
            ),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// HIGHLIGHT
// ===========================================================================

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circleCheck, size: 18, color: colors.primary),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// METRICS
// ===========================================================================

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<OutbreakMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final columns = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: columns == 2 ? 1.45 : 1.6,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];

        return _MetricCard(metric: metric);
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final OutbreakMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${metric.value}'
            '${metric.unit.trim().isEmpty ? '' : ' ${metric.unit}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 5),

          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// STATUS CHIP
// ===========================================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty ? 'Published' : _capitalize(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.activity, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// META CHIP
// ===========================================================================

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// EMPTY
// ===========================================================================

class _PublicEmptyState extends StatelessWidget {
  const _PublicEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClinicalIconTile(icon: icon, size: 72, iconSize: 34),

                      AppSpacing.gapLg,

                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      AppSpacing.gapSm,

                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// HELPERS
// ===========================================================================

Color _tone(BuildContext context, String value) {
  final colors = Theme.of(context).colorScheme;

  return switch (value.trim().toLowerCase()) {
    'critical' || 'emergency' => colors.error,
    'success' || 'resolved' => colors.tertiary,
    'info' => colors.primary,
    'neutral' => colors.onSurfaceVariant,
    _ => colors.secondary,
  };
}

String _date(DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();

  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}

String _capitalize(String value) {
  final normalized = value.trim();

  if (normalized.isEmpty) {
    return '';
  }

  return '${normalized[0].toUpperCase()}'
      '${normalized.substring(1).toLowerCase()}';
}

Future<void> _copyLink(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Link copied.')));
}

Future<void> _openExternal(BuildContext context, String value) async {
  final uri = Uri.tryParse(value.trim());

  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This resource link is invalid.')),
      );
    }

    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this resource.')),
      );
    }
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open this resource.')),
    );
  }
}
