import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/presentation/controllers/publication_guideline_controller.dart';
import 'package:user_app/features/guidelines/presentation/widgets/responsive_clinical_table.dart';

class PublicationTablePage extends ConsumerWidget {
  const PublicationTablePage({
    super.key,
    required this.guidelineId,
    required this.blockId,
  });

  final String guidelineId;
  final String blockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publication = ref.watch(publicationGuidelineProvider(guidelineId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinical table'),
            Text(
              'Reviewed guideline reference',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Copy table',
            onPressed: publication.hasValue
                ? () => _copyTable(context, ref)
                : null,
            icon: const Icon(LucideIcons.copy),
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: publication.when(
        loading: () => const AppLoadingView(message: 'Loading table...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Clinical table unavailable',
          message: 'The reviewed table could not be loaded.',
          onRetry: () {
            ref.invalidate(publicationGuidelineProvider(guidelineId));
          },
        ),
        data: (content) {
          final block = content.blocks
              .whereType<TableGuidelineBlock>()
              .where((item) => item.id == blockId)
              .firstOrNull;

          if (block == null) {
            return const _MissingViewerContent(
              icon: LucideIcons.table2,
              label: 'Table',
              message:
                  'This table is no longer available in the reviewed publication content.',
            );
          }

          return _FullTable(
            block: block,
            source: content.publication.sourceOrganization,
          );
        },
      ),
    );
  }

  Future<void> _copyTable(BuildContext context, WidgetRef ref) async {
    final content = ref
        .read(publicationGuidelineProvider(guidelineId))
        .valueOrNull;

    final block = content?.blocks
        .whereType<TableGuidelineBlock>()
        .where((item) => item.id == blockId)
        .firstOrNull;

    if (block == null) {
      return;
    }

    final value = <String>[
      if (block.payload.title.trim().isNotEmpty) block.payload.title.trim(),
      block.payload.columns.join('\t'),
      ...block.payload.rows.map((row) => row.join('\t')),
      if (block.payload.footnotes.isNotEmpty) '',
      ...block.payload.footnotes,
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: value));

    if (!context.mounted) {
      return;
    }

    AppMessage.success(context, 'Table copied to clipboard.');
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
  Widget build(BuildContext context, WidgetRef ref) {
    final publication = ref.watch(publicationGuidelineProvider(guidelineId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinical algorithm'),
            Text(
              'Reviewed guideline reference',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Copy source link',
            onPressed: () {
              _copyLink(context);
            },
            icon: const Icon(LucideIcons.share2),
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: publication.when(
        loading: () => const AppLoadingView(message: 'Loading algorithm...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Clinical algorithm unavailable',
          message: 'The reviewed algorithm could not be loaded.',
          onRetry: () {
            ref.invalidate(publicationGuidelineProvider(guidelineId));
          },
        ),
        data: (content) {
          final block = content.blocks
              .whereType<AlgorithmGuidelineBlock>()
              .where((item) => item.id == blockId)
              .firstOrNull;

          if (block == null) {
            return const _MissingViewerContent(
              icon: LucideIcons.workflow,
              label: 'Algorithm',
              message:
                  'This algorithm is no longer available in the reviewed publication content.',
            );
          }

          return _AlgorithmCanvas(
            block: block,
            source: content.publication.sourceOrganization,
          );
        },
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: AppRoutes.publicGuidelineAlgorithmView(guidelineId, blockId),
      ),
    );

    if (!context.mounted) {
      return;
    }

    AppMessage.success(context, 'Algorithm link copied.');
  }
}

// ===========================================================================
// TABLE VIEW
// ===========================================================================

class _FullTable extends StatefulWidget {
  const _FullTable({required this.block, required this.source});

  final TableGuidelineBlock block;
  final String source;

  @override
  State<_FullTable> createState() => _FullTableState();
}

class _FullTableState extends State<_FullTable> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final block = widget.block;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // -----------------------------------------------------------------
          // TABLE CONTEXT
          // -----------------------------------------------------------------
          _ViewerHeader(
            icon: LucideIcons.table2,
            title: block.payload.title.trim().isEmpty
                ? 'Clinical table'
                : block.payload.title.trim(),
            source: widget.source,
            pages: _pages(block.pageStart, block.pageEnd),
            helperText:
                '${block.payload.rows.length} rows • ${block.payload.columns.length} columns',
          ),

          // -----------------------------------------------------------------
          // TABLE BODY
          // -----------------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: ResponsiveClinicalTable(payload: block.payload),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // FOOTNOTES
          // -----------------------------------------------------------------
          if (block.payload.footnotes.isNotEmpty)
            _TableFootnotes(footnotes: block.payload.footnotes),
        ],
      ),
    );
  }
}

// ===========================================================================
// TABLE FOOTNOTES
// ===========================================================================

class _TableFootnotes extends StatelessWidget {
  const _TableFootnotes({required this.footnotes});

  final List<String> footnotes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: colors.primary),
              AppSpacing.hGapSm,
              Text(
                'Notes',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          AppSpacing.gapSm,
          for (var index = 0; index < footnotes.length; index++) ...[
            SelectableText(
              footnotes[index],
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (index < footnotes.length - 1) AppSpacing.gapSm,
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// ALGORITHM
// ===========================================================================

class _AlgorithmCanvas extends StatelessWidget {
  const _AlgorithmCanvas({required this.block, required this.source});

  final AlgorithmGuidelineBlock block;
  final String source;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          _ViewerHeader(
            icon: LucideIcons.workflow,
            title: block.payload.title.trim().isEmpty
                ? 'Reviewed clinical algorithm'
                : block.payload.title.trim(),
            source: source,
            pages: _pages(block.pageStart, block.pageEnd),
            helperText: '${block.payload.nodes.length} steps',
            warning:
                'Reference presentation only. This is not executable decision logic.',
          ),

          Expanded(child: _AlgorithmViewer(block: block)),
        ],
      ),
    );
  }
}

class _AlgorithmViewer extends StatelessWidget {
  const _AlgorithmViewer({required this.block});

  final AlgorithmGuidelineBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.payload.nodes.isEmpty) {
      return const _MissingViewerContent(
        icon: LucideIcons.workflow,
        label: 'Algorithm',
        message: 'This algorithm does not contain any reviewed steps.',
      );
    }

    return InteractiveViewer(
      minScale: 0.65,
      maxScale: 3,
      boundaryMargin: const EdgeInsets.all(180),
      constrained: false,
      child: SizedBox(
        width: 620,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              for (
                var index = 0;
                index < block.payload.nodes.length;
                index++
              ) ...[
                _AlgorithmNodeView(
                  node: block.payload.nodes[index],
                  position: index + 1,
                ),

                if (index < block.payload.nodes.length - 1)
                  const _AlgorithmConnector(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ALGORITHM NODE
// ===========================================================================

class _AlgorithmNodeView extends StatelessWidget {
  const _AlgorithmNodeView({required this.node, required this.position});

  final GuidelineAlgorithmNode node;
  final int position;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final kind = node.kind.trim().isEmpty ? 'Step' : node.kind.trim();

    return Semantics(
      container: true,
      label: '$kind. ${node.label}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$position',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                AppSpacing.hGapMd,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        node.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (node.next.isNotEmpty) ...[
              AppSpacing.gapMd,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.arrowRight,
                      size: 15,
                      color: colors.onSurfaceVariant,
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: SelectableText(
                        'Next: ${node.next.join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlgorithmConnector extends StatelessWidget {
  const _AlgorithmConnector();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Container(width: 2, height: 18, color: colors.outlineVariant),
          Icon(
            LucideIcons.chevronDown,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SHARED HEADER
// ===========================================================================

class _ViewerHeader extends StatelessWidget {
  const _ViewerHeader({
    required this.icon,
    required this.title,
    required this.source,
    required this.pages,
    required this.helperText,
    this.warning,
  });

  final IconData icon;
  final String title;
  final String source;
  final String pages;
  final String helperText;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final metadata = <String>[
      if (source.trim().isNotEmpty) source.trim(),
      if (pages.trim().isNotEmpty) pages.trim(),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),

              AppSpacing.hGapMd,

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

                    const SizedBox(height: 3),

                    if (metadata.isNotEmpty)
                      Text(
                        metadata.join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                    const SizedBox(height: 3),

                    Text(
                      helperText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (warning?.trim().isNotEmpty == true) ...[
            AppSpacing.gapSm,

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16,
                    color: colors.onSecondaryContainer,
                  ),

                  AppSpacing.hGapSm,

                  Expanded(
                    child: Text(
                      warning!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// MISSING CONTENT
// ===========================================================================

class _MissingViewerContent extends StatelessWidget {
  const _MissingViewerContent({
    required this.icon,
    required this.label,
    required this.message,
  });

  final IconData icon;
  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 28),
              ),

              AppSpacing.gapMd,

              Text(
                '$label unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),

              AppSpacing.gapSm,

              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PAGE LABEL
// ===========================================================================

String _pages(int? start, int? end) {
  if (start == null) {
    return '';
  }

  if (end == null || end == start) {
    return 'Source page $start';
  }

  return 'Source pages $start–$end';
}
