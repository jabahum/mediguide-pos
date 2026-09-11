part of '../screens/offline_content_page.dart';

class _OfflineLoading extends StatelessWidget {
  const _OfflineLoading();

  @override
  Widget build(BuildContext context) => const AppLoadingView(
    message: 'Loading offline content...',
    padding: AppSpacing.pagePadding,
  );
}

// ===========================================================================
// EMPTY / ERROR
// ===========================================================================
