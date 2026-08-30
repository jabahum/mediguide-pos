part of '../screens/document_reader_page.dart';

class _DocumentError extends StatelessWidget {
  const _DocumentError({
    required this.message,
    this.onRetry,
    this.onOpenOriginal,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ClinicalIconTile(
                icon: LucideIcons.fileWarning,
                size: 72,
                iconSize: 34,
              ),

              AppSpacing.gapLg,

              Text(
                'Document unavailable',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              AppSpacing.gapSm,

              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              if (onRetry != null) ...[
                AppSpacing.gapLg,

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Try again'),
                  ),
                ),
              ],

              if (onOpenOriginal != null) ...[
                AppSpacing.gapSm,

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpenOriginal,
                    icon: const Icon(LucideIcons.externalLink),
                    label: const Text('Open original PDF'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// DOWNLOAD / PREPARATION
// ===========================================================================

class _DocumentLoading extends StatelessWidget {
  const _DocumentLoading({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final normalized = progress?.clamp(0.0, 1.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ClinicalIconTile(
                icon: LucideIcons.fileText,
                size: 72,
                iconSize: 34,
              ),

              AppSpacing.gapLg,

              Text(
                'Preparing document',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),

              AppSpacing.gapSm,

              Text(
                normalized == null
                    ? 'Loading the clinical document...'
                    : 'Downloaded ${(normalized * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              AppSpacing.gapMd,

              SizedBox(
                width: double.infinity,
                child: LinearProgressIndicator(value: normalized),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// RENDERING OVERLAY
// ===========================================================================

class _PdfRenderingOverlay extends StatelessWidget {
  const _PdfRenderingOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),

          AppSpacing.gapMd,

          Text(
            'Rendering document...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// NAVIGATION BAR
// ===========================================================================

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
