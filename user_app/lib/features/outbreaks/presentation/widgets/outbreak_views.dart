import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';
import 'package:user_app/features/notifications/domain/notification_action_resolver.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';
import 'package:user_app/features/outbreaks/presentation/widgets/outbreak_metrics.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';
import 'package:user_app/shared/widgets/section_header.dart';

export 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';

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
        data: (page) {
          final items = page.items;
          if (items.isEmpty) {
            return const _PublicEmptyState(
              icon: LucideIcons.shieldCheck,
              title: 'No published outbreak updates',
              message:
                  'There are currently no public outbreak records available.',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(publicOutbreaksProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              children: [
                _FreshnessBanner(metadata: page.cache),
                if (page.cache.isOffline || page.cache.isStale)
                  AppSpacing.gapSm,
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
                if (page.hasMore)
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(publicOutbreaksProvider.notifier).loadMore(),
                    icon: const Icon(LucideIcons.chevronsDown),
                    label: const Text('Load more updates'),
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
        error: (error, _) => error is PublicContentUnavailableException
            ? _PublicUnavailableState(
                message: error.message,
                withdrawn: error.isWithdrawn,
              )
            : AppErrorView(
                error: error,
                title: 'Response hub unavailable',
                onRetry: () {
                  ref.invalidate(publicOutbreakProvider(outbreakId));
                },
              ),
        data: (content) {
          return _OutbreakDetail(content: content);
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
        data: (page) {
          final items = page.items;
          if (items.isEmpty) {
            return const _PublicEmptyState(
              icon: LucideIcons.fileText,
              title: 'No published situation reports',
              message: 'Reports will appear here after publication.',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(publicSituationReportsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              children: [
                _FreshnessBanner(metadata: page.cache),
                if (page.cache.isOffline || page.cache.isStale)
                  AppSpacing.gapSm,
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
                if (page.hasMore)
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(publicSituationReportsProvider.notifier)
                        .loadMore(),
                    icon: const Icon(LucideIcons.chevronsDown),
                    label: const Text('Load more reports'),
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
        error: (error, _) => error is PublicContentUnavailableException
            ? _PublicUnavailableState(
                message: error.message,
                withdrawn: error.isWithdrawn,
              )
            : AppErrorView(
                error: error,
                title: 'Situation report unavailable',
                onRetry: () {
                  ref.invalidate(publicSituationReportProvider(reportId));
                },
              ),
        data: (content) {
          return _SituationReportView(content: content);
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

    final tone = _statusTone(
      context,
      status: outbreak.status,
      visualTone: outbreak.visualTone,
    );

    return Semantics(
      button: true,
      label: '${outbreak.title}. Status ${_capitalize(outbreak.status)}',
      child: Material(
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
                            : 'Updated ${_date(context, outbreak.lastUpdate)}',
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
      ),
    );
  }
}

// ===========================================================================
// OUTBREAK DETAIL
// ===========================================================================

class _OutbreakDetail extends StatelessWidget {
  const _OutbreakDetail({required this.content});

  final PublicContent<PublicOutbreakDetail> content;

  @override
  Widget build(BuildContext context) {
    final detail = content.value;
    final outbreak = detail.outbreak;

    final tone = _statusTone(
      context,
      status: outbreak.status,
      visualTone: outbreak.visualTone,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        _FreshnessBanner(metadata: content.cache),
        if (content.cache.isOffline || content.cache.isStale) AppSpacing.gapSm,
        _OutbreakHero(outbreak: outbreak, color: tone),

        if (content.partialFailures.isNotEmpty) ...[
          AppSpacing.gapSm,
          _PartialContentBanner(sections: content.partialFailures),
        ],

        if (outbreak.metrics.isNotEmpty) ...[
          AppSpacing.gapLg,
          const SectionHeader(
            title: 'Current situation',
            subtitle: 'Published response indicators',
            icon: LucideIcons.chartNoAxesColumn,
          ),
          AppSpacing.gapSm,
          OutbreakMetricGrid(metrics: outbreak.metrics),
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

        if (detail.documents.isNotEmpty) ...[
          AppSpacing.gapLg,

          SectionHeader(
            title: 'Official documents and SOPs',
            subtitle: 'Clinically reviewed response guidance',
            icon: LucideIcons.files,
            onSeeAll: () => context.push(
              AppRoutes.outbreakDocumentsFor(detail.outbreak.id),
            ),
          ),

          AppSpacing.gapSm,

          for (final document in detail.documents)
            _OutbreakDocumentTile(
              document: document,
              onTap: () => context.push(
                AppRoutes.outbreakDocument(document.outbreakId, document.id),
              ),
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
                _openOutbreakResource(context, resource);
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
                  _date(context, outbreak.lastUpdate),
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
                    _date(context, date),
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

class _OutbreakDocumentTile extends StatelessWidget {
  const _OutbreakDocumentTile({required this.document, required this.onTap});

  final PublicOutbreakDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metadata = <String>[
      if (document.issuingAuthority.trim().isNotEmpty)
        document.issuingAuthority,
      if (document.version.trim().isNotEmpty) 'Version ${document.version}',
      if (document.language.trim().isNotEmpty) document.language.toUpperCase(),
      if (document.fileSize > 0) _fileSize(document.fileSize),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: ClinicalIconTile(
          icon: document.mimeType == 'application/pdf'
              ? LucideIcons.fileText
              : LucideIcons.file,
        ),
        title: Text(
          document.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              document.documentKind.split('_').map(_capitalize).join(' '),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (metadata.isNotEmpty)
              Text(
                metadata.join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(LucideIcons.download, size: 19),
        onTap: document.downloadUrl.trim().isEmpty ? null : onTap,
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
            _date(context, report.publicationDate),
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
  const _SituationReportView({required this.content});

  final PublicContent<PublicSituationReport> content;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final report = content.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        _FreshnessBanner(metadata: content.cache),
        if (content.cache.isOffline || content.cache.isStale) AppSpacing.gapSm,
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
                      label: _date(context, report.publicationDate),
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

          OutbreakMetricGrid(metrics: report.metrics),
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
// STATUS CHIP
// ===========================================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty ? 'Published' : _capitalize(status);

    return Semantics(
      label: 'Status $label',
      child: Container(
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.sizeOf(context).width - AppSpacing.xl * 2).clamp(
          120,
          360,
        ),
      ),
      child: Container(
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
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
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

class _FreshnessBanner extends StatelessWidget {
  const _FreshnessBanner({required this.metadata});

  final PublicCacheMetadata metadata;

  @override
  Widget build(BuildContext context) {
    if (!metadata.isOffline && !metadata.isStale && !metadata.isWithdrawn) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final message = metadata.isWithdrawn
        ? 'This public item has been withdrawn.'
        : metadata.isStale
        ? 'Offline copy — verify critical details when connectivity returns.'
        : 'Showing a verified offline copy.';
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: metadata.isStale
              ? colors.errorContainer
              : colors.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              metadata.isStale
                  ? LucideIcons.triangleAlert
                  : LucideIcons.cloudOff,
              size: 18,
            ),
            AppSpacing.hGapSm,
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _PublicUnavailableState extends StatelessWidget {
  const _PublicUnavailableState({
    required this.message,
    required this.withdrawn,
  });

  final String message;
  final bool withdrawn;

  @override
  Widget build(BuildContext context) => _PublicEmptyState(
    icon: withdrawn ? LucideIcons.fileX2 : LucideIcons.cloudOff,
    title: withdrawn ? 'Publication withdrawn' : 'Content unavailable',
    message: message,
  );
}

class _PartialContentBanner extends StatelessWidget {
  const _PartialContentBanner({required this.sections});

  final List<String> sections;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'Some sections could not be refreshed: ${sections.join(', ')}. Pull to retry.',
    ),
  );
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

Color _statusTone(
  BuildContext context, {
  required String status,
  required String visualTone,
}) {
  final colors = Theme.of(context).colorScheme;
  return switch (status.trim().toLowerCase()) {
    'active' => colors.error,
    'monitoring' => colors.tertiary,
    'contained' => colors.primary,
    'closed' => colors.onSurfaceVariant,
    _ => _tone(context, visualTone),
  };
}

String _date(BuildContext context, DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();

  return MaterialLocalizations.of(context).formatMediumDate(local);
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
  final api = Uri.parse(AppConfig.current.apiBaseUrl);
  final absolute = api.replace(path: value, query: null, fragment: null);
  await Clipboard.setData(ClipboardData(text: absolute.toString()));

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Link copied.')));
}

Future<void> _openOutbreakResource(
  BuildContext context,
  PublicOutbreakResource resource,
) async {
  if ((resource.resourceType == 'managed_document' ||
          resource.resourceType == 'downloadable_asset') &&
      _isManagedOutbreakAssetPath(resource.assetUrl)) {
    final base = Uri.parse('${AppConfig.current.apiBaseUrl}/');
    final target = base.resolve(resource.assetUrl.replaceFirst('/', ''));
    final launched = await launchUrl(
      target,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this managed document.')),
      );
    }
    return;
  }
  final target = NotificationActionResolver.fromOutbreakResource(
    type: resource.resourceType,
    url: resource.url,
    assetUrl: resource.assetUrl,
  );
  if (target?.location case final String location) {
    context.push(location);
    return;
  }
  if (target?.externalUri case final Uri uri) {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this trusted resource.')),
      );
    }
    return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This resource link is unavailable.')),
    );
  }
}

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}

bool _isManagedOutbreakAssetPath(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment) {
    return false;
  }
  final parts = uri.pathSegments;
  if (parts.length != 5 ||
      parts[0] != 'api' ||
      parts[1] != 'public' ||
      parts[2] != 'situation-reports' ||
      parts[4] != 'asset') {
    return false;
  }
  final id = parts[3].split('-');
  const lengths = <int>[8, 4, 4, 4, 12];
  if (id.length != lengths.length) return false;
  for (var index = 0; index < id.length; index++) {
    if (id[index].length != lengths[index] ||
        int.tryParse(id[index], radix: 16) == null) {
      return false;
    }
  }
  return true;
}
