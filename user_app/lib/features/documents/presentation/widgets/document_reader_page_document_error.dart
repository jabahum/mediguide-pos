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
