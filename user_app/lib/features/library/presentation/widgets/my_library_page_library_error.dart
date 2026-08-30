part of '../screens/my_library_page.dart';

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.library, size: 44),

            AppSpacing.gapMd,

            Text(message, textAlign: TextAlign.center),

            AppSpacing.gapMd,

            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
