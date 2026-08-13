import 'package:flutter/material.dart';

/// Reference-aligned rounded icon tile used by clinical lists and actions.
class ClinicalIconTile extends StatelessWidget {
  const ClinicalIconTile({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}
