part of '../screens/tools_page.dart';

class _ToolsFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ToolsFilterHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ToolsFilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
