part of '../screens/publication_guideline_page.dart';

class _OriginalDocumentReader extends StatelessWidget {
  const _OriginalDocumentReader({
    required this.publication,
    required this.manifest,
    required this.asset,
    required this.onOpen,
  });

  final GuidelinePublication publication;

  final GuidelineManifest manifest;

  final GuidelineAsset? asset;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const Icon(LucideIcons.fileText, size: 64),

              AppSpacing.gapMd,

              Text(
                publication.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              AppSpacing.gapSm,

              const Text(
                'Reviewed structured extraction is not available. '
                'Use the original document as the clinical source.',
                textAlign: TextAlign.center,
              ),

              AppSpacing.gapLg,

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (manifest.version.isNotEmpty)
                    Chip(label: Text('Version ${manifest.version}')),

                  Chip(
                    avatar: Icon(
                      manifest.hasOfflinePackage
                          ? LucideIcons.cloudDownload
                          : LucideIcons.cloudOff,
                      size: 18,
                    ),
                    label: Text(
                      manifest.hasOfflinePackage
                          ? 'Offline package available'
                          : 'Online source only',
                    ),
                  ),

                  if ((asset?.sizeBytes ?? 0) > 0)
                    Chip(label: Text(_fileSize(asset?.sizeBytes ?? 0))),

                  if (asset?.checksum.isNotEmpty == true)
                    const Chip(
                      avatar: Icon(LucideIcons.shieldCheck, size: 18),
                      label: Text('Checksum supplied'),
                    ),
                ],
              ),

              AppSpacing.gapLg,

              FilledButton.icon(
                onPressed: manifest.hasOriginalPdf ? onOpen : null,
                icon: const Icon(LucideIcons.externalLink),
                label: Text(
                  manifest.hasOriginalPdf
                      ? 'Open original document'
                      : 'Original unavailable',
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FILE SIZE
// =============================================================================

String _fileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// =============================================================================
// SECTION HEADER DELEGATE
// =============================================================================
