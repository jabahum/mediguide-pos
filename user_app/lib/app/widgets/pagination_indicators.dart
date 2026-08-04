import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:user_app/app/core/navigation/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/app_spacing.dart';
import '../utils/loading.dart';

/// Collection of reusable pagination indicator widgets for infinite scroll
class PaginationIndicators {
  PaginationIndicators._();

  /// First page error indicator - shown when initial data load fails
  static Widget firstPageError({
    required VoidCallback onRetry,
    String? title,
    String? subtitle,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? LucideIcons.wifiOff,
              size: 64,
              color: AppNavigator.theme.colorScheme.error,
            ),
            AppSpacing.gapMd,
            Text(
              title ?? 'failedToLoadData'.tr,
              style: AppNavigator.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapSm,
            Text(
              subtitle ?? 'pleaseCheckConnectionAndTryAgain'.tr,
              style: AppNavigator.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapLg,
            ElevatedButton(onPressed: onRetry, child: Text('tryAgain'.tr)),
          ],
        ),
      ),
    );
  }

  /// New page error indicator - shown when loading additional pages fails
  static Widget newPageError({
    required VoidCallback onRetry,
    String? title,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? LucideIcons.wifiOff,
              size: 48,
              color: AppNavigator.theme.colorScheme.error,
            ),
            AppSpacing.gapSm,
            Text(
              title ?? 'failedToLoadMore'.tr,
              style: AppNavigator.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapMd,
            ElevatedButton(onPressed: onRetry, child: Text('tryAgain'.tr)),
          ],
        ),
      ),
    );
  }

  /// First page loading indicator - shown while initial data loads
  static Widget firstPageProgress({String? loadingText}) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Loading.large(text: loadingText),
      ),
    );
  }

  /// New page loading indicator - shown while loading additional pages
  static Widget newPageProgress({String? loadingText}) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Center(child: Loading.medium(text: loadingText)),
    );
  }

  /// No items found indicator - shown when no data is available
  static Widget noItemsFound({
    String? title,
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? LucideIcons.search,
              size: 64,
              color: AppNavigator.theme.colorScheme.outline,
            ),
            AppSpacing.gapMd,
            Text(
              title ?? 'noItemsFound'.tr,
              style: AppNavigator.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapSm,
            Text(
              subtitle ?? 'tryAdjustingSearchOrFilters'.tr,
              style: AppNavigator.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[AppSpacing.gapLg, action],
          ],
        ),
      ),
    );
  }

  /// No more items indicator - shown when all data has been loaded
  static Widget noMoreItems({String? message}) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Center(
        child: Text(
          message ?? 'youHaveReachedTheEnd'.tr,
          style: AppNavigator.textTheme.bodySmall?.copyWith(
            color: AppNavigator.theme.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
