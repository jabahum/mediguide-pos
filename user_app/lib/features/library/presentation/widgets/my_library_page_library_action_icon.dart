part of '../screens/my_library_page.dart';

class _LibraryActionIcon extends StatelessWidget {
  const _LibraryActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: colors.primary, size: 19),
    );
  }
}
