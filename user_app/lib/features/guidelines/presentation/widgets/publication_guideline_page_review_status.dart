part of '../screens/publication_guideline_page.dart';

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus({required this.manifest});

  final GuidelineManifest manifest;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (manifest.recommendedMode) {
      GuidelineReaderMode.structured => (
        'Reviewed structured content',
        AppStatusTone.success,
        LucideIcons.badgeCheck,
      ),

      GuidelineReaderMode.partial => (
        'Partially structured; verify source pages',
        AppStatusTone.warning,
        LucideIcons.fileWarning,
      ),

      GuidelineReaderMode.originalDocument => (
        'Original document is the clinical source',
        AppStatusTone.neutral,
        LucideIcons.fileText,
      ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: AppStatusBadge(icon: icon, tone: tone, label: label),
    );
  }
}

// =============================================================================
// NEW BOTTOM ACTION BAR
// =============================================================================
