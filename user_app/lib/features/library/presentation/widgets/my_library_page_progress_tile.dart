part of '../screens/my_library_page.dart';

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.progress,
    required this.publication,
    this.showNotes = false,
    this.onBeforeNavigate,
  });

  final ReadingProgress progress;
  final GuidelinePublication? publication;
  final bool showNotes;
  final VoidCallback? onBeforeNavigate;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.progressPercentage.clamp(0.0, 1.0);

    final progressPercent = (progressValue * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          onBeforeNavigate?.call();

          _openProgress(context, progress);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClinicalIconTile(icon: LucideIcons.bookOpenText),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication?.title ?? 'Saved guideline',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),

                    AppSpacing.gapSm,

                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          '$progressPercent%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock3,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            progress.lastReadFormatted,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),

                        if (progress.isBookmarked)
                          const Icon(LucideIcons.bookmarkCheck, size: 17),
                      ],
                    ),

                    if (showNotes && progress.notes.trim().isNotEmpty) ...[
                      AppSpacing.gapSm,

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.notebookPen, size: 16),

                            AppSpacing.hGapSm,

                            Expanded(
                              child: Text(
                                progress.notes,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              AppSpacing.hGapSm,

              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(LucideIcons.chevronRight, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProgress(BuildContext context, ReadingProgress progress) {
    //
    // Resume directly in the reader instead of returning to
    // the guideline overview.
    //
    var location = AppRoutes.readPublicGuideline(progress.guidelineId);

    //
    // If there is a saved section, use the reader's deep-link handling
    // that we added to PublicationGuidelinePage.
    //
    final currentSection = progress.currentSection.trim();

    if (currentSection.isNotEmpty) {
      location =
          '$location'
          '?section=${Uri.encodeQueryComponent(currentSection)}';
    }

    context.push(location);
  }
}
