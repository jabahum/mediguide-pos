import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/presentation/controllers/publication_guideline_controller.dart';

class PublicationTablePage extends ConsumerWidget {
  const PublicationTablePage({
    super.key,
    required this.guidelineId,
    required this.blockId,
  });
  final String guidelineId;
  final String blockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Clinical table'),
      actions: [
        IconButton(
          tooltip: 'Copy table',
          onPressed: () => _copyTable(context, ref),
          icon: const Icon(LucideIcons.copy),
        ),
      ],
    ),
    body: ref
        .watch(publicationGuidelineProvider(guidelineId))
        .when(
          loading: () => const AppLoadingView(message: 'Loading table…'),
          error: (error, _) => AppErrorView(
            error: error,
            title: 'Clinical table unavailable',
            onRetry: () =>
                ref.invalidate(publicationGuidelineProvider(guidelineId)),
          ),
          data: (content) {
            final block = content.blocks
                .whereType<TableGuidelineBlock>()
                .where((item) => item.id == blockId)
                .firstOrNull;
            if (block == null) {
              return const _MissingViewerContent(label: 'Table');
            }
            return _FullTable(
              block: block,
              source: content.publication.sourceOrganization,
            );
          },
        ),
  );

  Future<void> _copyTable(BuildContext context, WidgetRef ref) async {
    final content = ref
        .read(publicationGuidelineProvider(guidelineId))
        .valueOrNull;
    final block = content?.blocks
        .whereType<TableGuidelineBlock>()
        .where((item) => item.id == blockId)
        .firstOrNull;
    if (block == null) return;
    final value = [
      block.payload.columns.join('\t'),
      ...block.payload.rows.map((row) => row.join('\t')),
      ...block.payload.footnotes,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Table copied.')));
    }
  }
}

class PublicationAlgorithmPage extends ConsumerWidget {
  const PublicationAlgorithmPage({
    super.key,
    required this.guidelineId,
    required this.blockId,
  });
  final String guidelineId;
  final String blockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Clinical algorithm'),
      actions: [
        IconButton(
          tooltip: 'Copy source link',
          onPressed: () => _copyLink(context),
          icon: const Icon(LucideIcons.share2),
        ),
      ],
    ),
    body: ref
        .watch(publicationGuidelineProvider(guidelineId))
        .when(
          loading: () => const AppLoadingView(message: 'Loading algorithm…'),
          error: (error, _) => AppErrorView(
            error: error,
            title: 'Clinical algorithm unavailable',
            onRetry: () =>
                ref.invalidate(publicationGuidelineProvider(guidelineId)),
          ),
          data: (content) {
            final block = content.blocks
                .whereType<AlgorithmGuidelineBlock>()
                .where((item) => item.id == blockId)
                .firstOrNull;
            if (block == null) {
              return const _MissingViewerContent(label: 'Algorithm');
            }
            return _AlgorithmCanvas(
              block: block,
              source: content.publication.sourceOrganization,
            );
          },
        ),
  );

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: AppRoutes.publicGuidelineAlgorithmView(guidelineId, blockId),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Algorithm link copied.')));
    }
  }
}

class _FullTable extends StatelessWidget {
  const _FullTable({required this.block, required this.source});
  final TableGuidelineBlock block;
  final String source;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.pagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.payload.title.isNotEmpty)
          Text(
            block.payload.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        AppSpacing.gapSm,
        Text(
          [
            source,
            _pages(block.pageStart, block.pageEnd),
          ].where((value) => value.isNotEmpty).join(' • '),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        AppSpacing.gapMd,
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: block.payload.columns
                      .map(
                        (column) => DataColumn(
                          label: Text(
                            column,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                      .toList(),
                  rows: block.payload.rows
                      .map(
                        (row) => DataRow(
                          cells: List.generate(
                            block.payload.columns.length,
                            (index) => DataCell(
                              SelectableText(
                                index < row.length ? row[index] : '',
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        for (final footnote in block.payload.footnotes)
          Text(footnote, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _AlgorithmCanvas extends StatelessWidget {
  const _AlgorithmCanvas({required this.block, required this.source});
  final AlgorithmGuidelineBlock block;
  final String source;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.payload.title.isEmpty
                  ? 'Reviewed clinical algorithm'
                  : block.payload.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.gapXs,
            const Text(
              'Presentation content only. This flow is not executable decision logic.',
            ),
            if (source.isNotEmpty || block.pageStart != null)
              Text(
                [
                  source,
                  _pages(block.pageStart, block.pageEnd),
                ].where((value) => value.isNotEmpty).join(' • '),
              ),
          ],
        ),
      ),
      Expanded(
        child: InteractiveViewer(
          minScale: 0.6,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(200),
          constrained: false,
          child: SizedBox(
            width: 600,
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < block.payload.nodes.length;
                    index++
                  ) ...[
                    _AlgorithmNodeView(node: block.payload.nodes[index]),
                    if (index < block.payload.nodes.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Icon(LucideIcons.arrowDown),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _AlgorithmNodeView extends StatelessWidget {
  const _AlgorithmNodeView({required this.node});
  final GuidelineAlgorithmNode node;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${node.kind}. ${node.label}',
    child: Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Text(
              node.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (node.next.isNotEmpty) ...[
              AppSpacing.gapSm,
              Text(
                'Next: ${node.next.join(', ')}',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _MissingViewerContent extends StatelessWidget {
  const _MissingViewerContent({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('$label content is unavailable.'));
}

String _pages(int? start, int? end) {
  if (start == null) return '';
  return end == null || end == start
      ? 'Source page $start'
      : 'Source pages $start–$end';
}
