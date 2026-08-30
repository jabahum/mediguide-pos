part of '../screens/document_reader_page.dart';

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
