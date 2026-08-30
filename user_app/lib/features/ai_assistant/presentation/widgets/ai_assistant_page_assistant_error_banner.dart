part of '../screens/ai_assistant_page.dart';

class _AssistantErrorBanner extends StatelessWidget {
  const _AssistantErrorBanner({
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            color: colors.onErrorContainer,
            size: 18,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),

          TextButton(
            onPressed: isRetrying ? null : onRetry,
            child: Text(isRetrying ? 'Retrying...' : 'Retry'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SOURCES
// ===========================================================================
