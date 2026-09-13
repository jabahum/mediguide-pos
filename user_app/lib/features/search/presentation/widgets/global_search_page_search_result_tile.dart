part of '../screens/global_search_page.dart';

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({required this.result, required this.query});

  final SearchResult result;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final outbreak = result.getItem<PublicOutbreak>();
    final outbreakTone = outbreak == null
        ? null
        : outbreak.status.toLowerCase() == 'active'
        ? colors.error
        : colors.tertiary;

    final canOpen =
        result.route?.trim().isNotEmpty == true ||
        result.externalUrl?.trim().isNotEmpty == true;

    return Semantics(
      button: canOpen,
      enabled: canOpen,
      label: '${result.title}. ${result.category.displayName}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: outbreakTone?.withValues(alpha: 0.045),
        shape: outbreakTone == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: outbreakTone.withValues(alpha: 0.28)),
              ),
        child: InkWell(
          onTap: !canOpen
              ? null
              : () async {
                  await ref
                      .read(globalSearchControllerProvider.notifier)
                      .recordSelection(result);
                  if (!context.mounted) return;
                  if (result.externalUrl case final String value) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Open external official resource?'),
                        content: Text(
                          'You are leaving MediGuide and opening:\n$value',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Open website'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        final launched = await launchUrl(
                          Uri.parse(value),
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched && context.mounted) {
                          AppMessage.error(
                            context,
                            'Unable to open this official resource.',
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          AppMessage.error(
                            context,
                            'Unable to open this official resource.',
                          );
                        }
                      }
                    }
                    return;
                  }
                  context.push(result.route!, extra: result.item);
                },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClinicalIconTile(icon: iconFor(result.category)),

                AppSpacing.hGapMd,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedText(
                        text: result.title,
                        query: query,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),

                      if (outbreak != null) ...[
                        const SizedBox(height: 7),
                        _OutbreakSearchBadge(
                          status: outbreak.status,
                          color: outbreakTone!,
                        ),
                      ],

                      const SizedBox(height: 5),

                      _SearchCategoryLabel(category: result.category),

                      if (result.subtitle?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),

                        _HighlightedText(
                          text: result.subtitle!,
                          query: query,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ],

                      if (result.description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        _HighlightedText(
                          text: result.description!,
                          query: query,
                          maxLines: 3,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.35),
                        ),
                      ],

                      if (result.isOffline || result.isStale) ...[
                        const SizedBox(height: 8),
                        _SearchAvailabilityBadge(
                          offline: result.isOffline,
                          stale: result.isStale,
                        ),
                      ],
                    ],
                  ),
                ),

                if (canOpen) ...[
                  AppSpacing.hGapSm,

                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: colors.onSurfaceVariant,
                      size: 19,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData iconFor(SearchCategory category) {
    return switch (category) {
      SearchCategory.drugs => LucideIcons.pill,
      SearchCategory.diseases => LucideIcons.activity,
      SearchCategory.hubs => LucideIcons.layoutGrid,
      SearchCategory.pillars => LucideIcons.folderOpen,
      SearchCategory.guidelines => LucideIcons.bookOpenText,
      SearchCategory.consultants => LucideIcons.stethoscope,
      SearchCategory.healthFacilities => LucideIcons.hospital,
      SearchCategory.abbreviations => LucideIcons.languages,
      SearchCategory.faq => LucideIcons.circleHelp,
      SearchCategory.outbreaks => LucideIcons.siren,
      SearchCategory.outbreakDocuments => LucideIcons.files,
      SearchCategory.outbreakResources => LucideIcons.externalLink,
      SearchCategory.situationReports => LucideIcons.fileChartColumn,
      SearchCategory.tools => LucideIcons.calculator,
      SearchCategory.all => LucideIcons.search,
    };
  }
}
