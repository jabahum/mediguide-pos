part of '../screens/guest_home_page.dart';

class _CategoryQuickAccessGrid extends StatelessWidget {
  const _CategoryQuickAccessGrid({
    required this.categories,
    required this.onCategory,
  });

  final List<({String id, String name})> categories;
  final ValueChanged<({String id, String name})> onCategory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        //
        // This intentionally mirrors the Quick Access layout:
        //
        // normal phone  -> 4 columns
        // narrow phone  -> 2 columns
        // larger device -> still compact, up to 4
        //
        final columns = constraints.maxWidth >= 340 ? 4 : 2;

        final textScale = MediaQuery.textScalerOf(context).scale(1);

        final largeText = textScale >= 1.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: largeText
                ? 0.72
                : columns == 4
                ? 0.86
                : 1.45,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return _CategoryQuickAccessTile(
              label: category.name,
              onTap: () {
                onCategory(category);
              },
            );
          },
        );
      },
    );
  }
}
