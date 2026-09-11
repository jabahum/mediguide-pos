part of '../screens/document_reader_page.dart';

class _PdfRenderingOverlay extends StatelessWidget {
  const _PdfRenderingOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppShimmer(child: AppSkeleton(width: 180, height: 220)),

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
