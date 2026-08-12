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
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';
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

class OutbreakHubPage extends ConsumerWidget {
  const OutbreakHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Outbreak response hub'),
      actions: [
        TextButton(
          onPressed: () => context.push(AppRoutes.situationReports),
          child: const Text('Reports'),
        ),
      ],
    ),
    body: ref
        .watch(publicOutbreaksProvider)
        .when(
          loading: () =>
              const AppLoadingView(message: 'Loading public updates…'),
          error: (error, _) => AppErrorView(
            error: error,
            title: 'Public updates unavailable',
            message: 'No outbreak information can be shown right now.',
            onRetry: () => ref.invalidate(publicOutbreaksProvider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async => ref.refresh(publicOutbreaksProvider.future),
            child: items.isEmpty
                ? const _PublicEmptyState(
                    icon: LucideIcons.shieldCheck,
                    title: 'No published outbreak updates',
                    message:
                        'The backend has not published any active or historical outbreak records.',
                  )
                : ListView.separated(
                    padding: AppSpacing.pagePadding,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => AppSpacing.gapSm,
                    itemBuilder: (context, index) => _OutbreakCard(
                      outbreak: items[index],
                      onTap: () =>
                          context.push(AppRoutes.outbreak(items[index].id)),
                    ),
                  ),
          ),
        ),
  );
}

class OutbreakDetailPage extends ConsumerWidget {
  const OutbreakDetailPage({super.key, required this.outbreakId});
  final String outbreakId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Response hub'),
      actions: [
        IconButton(
          tooltip: 'Copy outbreak link',
          onPressed: () => _copyLink(context, AppRoutes.outbreak(outbreakId)),
          icon: const Icon(LucideIcons.share2),
        ),
      ],
    ),
    body: ref
        .watch(publicOutbreakProvider(outbreakId))
        .when(
          loading: () => const AppLoadingView(message: 'Loading response hub…'),
          error: (error, _) => AppErrorView(
            error: error,
            title: 'Response hub unavailable',
            onRetry: () => ref.invalidate(publicOutbreakProvider(outbreakId)),
          ),
          data: (detail) => _OutbreakDetail(detail: detail),
        ),
  );
}

class SituationReportsPage extends ConsumerWidget {
  const SituationReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Situation reports')),
    body: ref
        .watch(publicSituationReportsProvider)
        .when(
          loading: () => const AppLoadingView(message: 'Loading reports…'),
          error: (error, _) => AppErrorView(
            error: error,
            title: 'Situation reports unavailable',
            onRetry: () => ref.invalidate(publicSituationReportsProvider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(publicSituationReportsProvider.future),
            child: items.isEmpty
                ? const _PublicEmptyState(
                    icon: LucideIcons.fileText,
                    title: 'No published situation reports',
                    message:
                        'Reports will appear after an authorized publisher makes them public.',
                  )
                : ListView.separated(
                    padding: AppSpacing.pagePadding,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => AppSpacing.gapSm,
                    itemBuilder: (context, index) {
                      final report = items[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(LucideIcons.fileChartColumn, size: 20),
                          ),
                          title: Text(report.title),
                          subtitle: Text(
                            [
                              report.geographicArea,
                              _date(report.publicationDate),
                              report.sourceOrganization,
                            ].where((value) => value.isNotEmpty).join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(LucideIcons.chevronRight),
                          onTap: () => context.push(
                            AppRoutes.situationReport(report.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
  );
}

class SituationReportDetailPage extends ConsumerWidget {
  const SituationReportDetailPage({super.key, required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Situation report'),
      actions: [
        IconButton(
          tooltip: 'Copy report link',
          onPressed: () =>
              _copyLink(context, AppRoutes.situationReport(reportId)),
          icon: const Icon(LucideIcons.share2),
        ),
      ],
    ),
    body: ref
        .watch(publicSituationReportProvider(reportId))
        .when(
          loading: () => const AppLoadingView(message: 'Loading report…'),
          error: (error, _) => AppErrorView(
            error: error,
            title: 'Situation report unavailable',
            onRetry: () =>
                ref.invalidate(publicSituationReportProvider(reportId)),
          ),
          data: (report) => _SituationReportView(report: report),
        ),
  );
}

class _OutbreakCard extends StatelessWidget {
  const _OutbreakCard({required this.outbreak, required this.onTap});
  final PublicOutbreak outbreak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _tone(context, outbreak.visualTone);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (largeText) ...[
                Row(
                  children: [
                    Icon(LucideIcons.siren, color: color),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Text(
                        outbreak.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusChip(status: outbreak.status, color: color),
                ),
              ] else
                Row(
                  children: [
                    Icon(LucideIcons.siren, color: color),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Text(
                        outbreak.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _StatusChip(status: outbreak.status, color: color),
                  ],
                ),
              if (outbreak.geographicArea.isNotEmpty) ...[
                AppSpacing.gapSm,
                Text(outbreak.geographicArea),
              ],
              if (outbreak.summary.isNotEmpty) ...[
                AppSpacing.gapSm,
                Text(
                  outbreak.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              AppSpacing.gapSm,
              Text(
                'Last updated ${_date(outbreak.lastUpdate)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutbreakDetail extends StatelessWidget {
  const _OutbreakDetail({required this.detail});
  final PublicOutbreakDetail detail;

  @override
  Widget build(BuildContext context) {
    final outbreak = detail.outbreak;
    final color = _tone(context, outbreak.visualTone);
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChip(status: outbreak.status, color: color),
              AppSpacing.gapSm,
              Text(
                outbreak.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (outbreak.geographicArea.isNotEmpty)
                Text(outbreak.geographicArea),
              AppSpacing.gapSm,
              Text(outbreak.summary),
              if (outbreak.sourceOrganization.isNotEmpty) ...[
                AppSpacing.gapSm,
                Text('Source: ${outbreak.sourceOrganization}'),
              ],
            ],
          ),
        ),
        if (outbreak.metrics.isNotEmpty) ...[
          AppSpacing.gapLg,
          _MetricGrid(metrics: outbreak.metrics),
        ],
        if (detail.resources.isNotEmpty) ...[
          AppSpacing.gapLg,
          const SectionHeader(
            title: 'Quick resources',
            icon: LucideIcons.layoutGrid,
          ),
          AppSpacing.gapSm,
          for (final resource in detail.resources)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(LucideIcons.externalLink),
                title: Text(resource.title),
                subtitle: Text(resource.resourceType),
                onTap: () => _open(
                  resource.url.isNotEmpty ? resource.url : resource.assetUrl,
                ),
              ),
            ),
        ],
        if (detail.updates.isNotEmpty) ...[
          AppSpacing.gapLg,
          const SectionHeader(title: 'Latest updates', icon: LucideIcons.clock),
          AppSpacing.gapSm,
          for (final update in detail.updates)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.circleDot),
              title: Text(update.title),
              subtitle: Text('${_date(update.publishedAt)}\n${update.summary}'),
            ),
        ],
        if (detail.reports.isNotEmpty) ...[
          AppSpacing.gapLg,
          const SectionHeader(
            title: 'Situation reports',
            icon: LucideIcons.fileChartColumn,
          ),
          for (final report in detail.reports)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(report.title),
              subtitle: Text(_date(report.publicationDate)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push(AppRoutes.situationReport(report.id)),
            ),
        ],
      ],
    );
  }
}

class _SituationReportView extends StatelessWidget {
  const _SituationReportView({required this.report});
  final PublicSituationReport report;

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.pagePadding,
    children: [
      Text(report.title, style: Theme.of(context).textTheme.headlineSmall),
      AppSpacing.gapSm,
      Text(
        [
          report.geographicArea,
          _date(report.publicationDate),
        ].where((value) => value.isNotEmpty).join(' • '),
      ),
      if (report.sourceOrganization.isNotEmpty)
        Text('Source: ${report.sourceOrganization}'),
      AppSpacing.gapLg,
      Text(report.summary),
      if (report.metrics.isNotEmpty) ...[
        AppSpacing.gapLg,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.circleCheck, size: 18),
                AppSpacing.gapSm,
                Expanded(child: Text(highlight)),
              ],
            ),
          ),
      ],
      if (report.reportAssetUrl.isNotEmpty) ...[
        AppSpacing.gapLg,
        FilledButton.icon(
          onPressed: () => context.push(
            AppRoutes.documentReader,
            extra: DocumentReaderArgs(
              title: report.title,
              source: report.reportAssetUrl,
            ),
          ),
          icon: const Icon(LucideIcons.fileDown),
          label: const Text('View full report'),
        ),
      ],
    ],
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<OutbreakMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: textScale >= 1.5 ? 200 : 136,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${metric.value}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(metric.label, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(LucideIcons.activity, size: 16, color: color),
    label: Text(status.isEmpty ? 'Published' : status),
  );
}

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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48),
                AppSpacing.gapMd,
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapSm,
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Color _tone(BuildContext context, String value) => switch (value) {
  'critical' => Theme.of(context).colorScheme.error,
  'success' => Colors.green.shade700,
  'info' => Theme.of(context).colorScheme.primary,
  'neutral' => Theme.of(context).colorScheme.outline,
  _ => Colors.orange.shade800,
};

String _date(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

Future<void> _copyLink(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied.')));
  }
}

Future<void> _open(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
