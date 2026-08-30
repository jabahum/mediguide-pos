import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:universal_image/universal_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/presentation/widgets/responsive_clinical_table.dart';

class PublicationBlockView extends StatelessWidget {
  const PublicationBlockView({
    super.key,
    required this.block,
    this.guidelineId,
  });

  final GuidelineBlock block;
  final String? guidelineId;

  @override
  Widget build(BuildContext context) => switch (block) {
    ParagraphGuidelineBlock(:final text, :final pageStart, :final pageEnd) =>
      _TextBlock(text: text, pageStart: pageStart, pageEnd: pageEnd),
    HeadingGuidelineBlock(:final text, :final level) => Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          text,
          style: level <= 2
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ),
    OrderedListGuidelineBlock(:final items) => _ListBlock(
      items: items,
      ordered: true,
    ),
    UnorderedListGuidelineBlock(:final items) => _ListBlock(
      items: items,
      ordered: false,
    ),
    TableGuidelineBlock(:final payload, :final pageStart, :final pageEnd) =>
      _TableBlock(
        payload: payload,
        pageStart: pageStart,
        pageEnd: pageEnd,
        onOpen: guidelineId == null
            ? null
            : () => context.push(
                AppRoutes.publicGuidelineTableView(guidelineId!, block.id),
              ),
      ),
    FigureGuidelineBlock(:final payload, :final asset) => _FigureBlock(
      payload: payload,
      asset: asset,
    ),
    CalloutGuidelineBlock(:final blockType, :final payload) => _CalloutBlock(
      blockType: blockType,
      payload: payload,
    ),
    AlgorithmGuidelineBlock(:final payload, :final pageStart) =>
      _AlgorithmBlock(
        payload: payload,
        pageStart: pageStart,
        onOpen: guidelineId == null
            ? null
            : () => context.push(
                AppRoutes.publicGuidelineAlgorithmView(guidelineId!, block.id),
              ),
      ),
    ReferenceGuidelineBlock(:final citation, :final url) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(LucideIcons.bookMarked),
      title: Text(citation),
      subtitle: url.isEmpty ? null : Text(url),
      onTap: url.isEmpty ? null : () => _openReference(context, url),
    ),
    PageBreakGuidelineBlock(:final page) => Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: AppSpacing.hPaddingSm,
          child: Text('Original page $page'),
        ),
        const Expanded(child: Divider()),
      ],
    ),
    UnknownGuidelineBlock(:final rawType) => Semantics(
      label: 'Unsupported guideline content type $rawType',
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.fileQuestion),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  'This content type is not supported by this app version. '
                  'Open the original document to view it safely.',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  };
}

Future<void> _openReference(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https') {
    AppMessage.warning(context, 'This reference link is unavailable.');
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppMessage.error(context, 'Unable to open this reference.');
    }
  } catch (_) {
    if (context.mounted) {
      AppMessage.error(context, 'Unable to open this reference.');
    }
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.text, this.pageStart, this.pageEnd});
  final String text;
  final int? pageStart;
  final int? pageEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText(text, style: Theme.of(context).textTheme.bodyLarge),
      if (pageStart != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            pageEnd == null || pageEnd == pageStart
                ? 'Source page $pageStart'
                : 'Source pages $pageStart–$pageEnd',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
    ],
  );
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.items, required this.ordered});
  final List<String> items;
  final bool ordered;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < items.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: Text(ordered ? '${index + 1}.' : '•')),
              Expanded(child: SelectableText(items[index])),
            ],
          ),
        ),
    ],
  );
}

class _TableBlock extends StatelessWidget {
  const _TableBlock({
    required this.payload,
    this.pageStart,
    this.pageEnd,
    this.onOpen,
  });
  final GuidelineTablePayload payload;
  final int? pageStart;
  final int? pageEnd;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    label: payload.title.isEmpty ? 'Clinical table' : payload.title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveClinicalTable(payload: payload, showTitle: true),
        for (final footnote in payload.footnotes)
          Text(footnote, style: Theme.of(context).textTheme.bodySmall),
        if (onOpen != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(LucideIcons.maximize2),
              label: const Text('Open full table'),
            ),
          ),
      ],
    ),
  );
}

class _FigureBlock extends StatelessWidget {
  const _FigureBlock({required this.payload, required this.asset});
  final GuidelineFigurePayload payload;
  final GuidelineAsset? asset;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: payload.alternativeText,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (asset?.url.isNotEmpty == true)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: UniversalImage(
              asset!.url,
              fit: BoxFit.contain,
              semanticLabel: payload.alternativeText,
            ),
          )
        else
          const _UnavailableContent(label: 'Figure unavailable'),
        if (payload.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(payload.caption),
          ),
      ],
    ),
  );
}

class _CalloutBlock extends StatelessWidget {
  const _CalloutBlock({required this.blockType, required this.payload});
  final String blockType;
  final GuidelineCalloutPayload payload;

  @override
  Widget build(BuildContext context) {
    final isWarning = const {
      'warning',
      'caution',
      'contraindication',
    }.contains(blockType);
    final color = isWarning
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Semantics(
      label:
          '${payload.title.isEmpty ? blockType : payload.title}. '
          '${payload.content}',
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isWarning
                        ? LucideIcons.triangleAlert
                        : LucideIcons.badgeCheck,
                    color: color,
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: Text(
                      payload.title.isEmpty
                          ? blockType.replaceAll('_', ' ')
                          : payload.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              SelectableText(payload.content),
              if (payload.evidenceGrade.isNotEmpty)
                Text('Evidence: ${payload.evidenceGrade}'),
              if (payload.source.isNotEmpty) Text('Source: ${payload.source}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlgorithmBlock extends StatelessWidget {
  const _AlgorithmBlock({required this.payload, this.pageStart, this.onOpen});
  final GuidelineAlgorithmPayload payload;
  final int? pageStart;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payload.title.isEmpty ? 'Clinical algorithm' : payload.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.gapSm,
          const Text(
            'Reviewed visual sequence. This is not executable decision logic.',
          ),
          AppSpacing.gapSm,
          for (final node in payload.nodes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.workflow),
              title: Text(node.label),
              subtitle: node.kind.isEmpty ? null : Text(node.kind),
            ),
          if (pageStart != null) Text('Source page $pageStart'),
          if (onOpen != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(LucideIcons.maximize2),
                label: const Text('Open algorithm'),
              ),
            ),
        ],
      ),
    ),
  );
}

class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 120),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label),
  );
}
