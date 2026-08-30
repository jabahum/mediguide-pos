part of '../screens/all_actions_page.dart';

class _ScrollableStateContainer extends StatelessWidget {
  const _ScrollableStateContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        child,
      ],
    );
  }
}
