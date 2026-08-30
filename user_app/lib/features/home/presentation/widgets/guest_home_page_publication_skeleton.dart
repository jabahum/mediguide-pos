part of '../screens/guest_home_page.dart';

class _PublicationSkeleton extends StatelessWidget {
  const _PublicationSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (var index = 0; index < 3; index++)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SizedBox(
              height: 84,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    AppSpacing.hGapMd,

                    const Expanded(
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// ERROR
// =============================================================================
