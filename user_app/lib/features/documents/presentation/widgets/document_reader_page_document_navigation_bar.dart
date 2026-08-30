part of '../screens/document_reader_page.dart';

class _DocumentNavigationBar extends StatelessWidget {
  const _DocumentNavigationBar({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenOriginal,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasPages = pageCount > 0;

    final progress = hasPages
        ? ((currentPage + 1) / pageCount).clamp(0.0, 1.0)
        : null;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress != null)
              LinearProgressIndicator(value: progress, minHeight: 2),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: onPrevious,
                    icon: const Icon(LucideIcons.chevronLeft),
                  ),

                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasPages
                                ? 'Page ${currentPage + 1} of $pageCount'
                                : 'Preparing pages',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),

                          if (hasPages)
                            Text(
                              '${(progress! * 100).round()}% through document',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Next page',
                    onPressed: onNext,
                    icon: const Icon(LucideIcons.chevronRight),
                  ),

                  IconButton(
                    tooltip: 'Open original PDF',
                    onPressed: onOpenOriginal,
                    icon: const Icon(LucideIcons.externalLink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
