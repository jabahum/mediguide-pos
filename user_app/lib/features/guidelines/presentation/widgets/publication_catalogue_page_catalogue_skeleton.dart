part of '../screens/publication_catalogue_page.dart';

class _CatalogueSkeleton extends StatelessWidget {
  const _CatalogueSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        0,
        Responsive.horizontalPadding(context),
        AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          for (var index = 0; index < 6; index++) ...[
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(height: 42, width: 42),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton(height: 18, width: 240),
                          AppSpacing.gapSm,
                          AppSkeleton(height: 13, width: 160),
                          AppSpacing.gapSm,
                          AppSkeleton(height: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index < 5) AppSpacing.gapSm,
          ],
        ],
      ),
    );
  }
}
