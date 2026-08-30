part of '../screens/guest_home_page.dart';

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 340 ? 4 : 2;

        final textScale = MediaQuery.textScalerOf(context).scale(1);

        final largeText = textScale >= 1.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _QuickActionCard(action: actions[index]);
          },
        );
      },
    );
  }
}
