part of '../screens/home_page.dart';

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Original compact behavior:
        // 4 across on normal phones, 2 only on very narrow screens.
        final columns = constraints.maxWidth >= 340 ? 4 : 2;
        final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,

            // Keeps approximately the same compact sizing
            // as the original HomePage.
            childAspectRatio: largeText
                ? 0.68
                : columns == 4
                ? 0.86
                : 1.15,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _QuickActionCard(
              action: actions[index],
              compact: columns == 4,
            );
          },
        );
      },
    );
  }
}
