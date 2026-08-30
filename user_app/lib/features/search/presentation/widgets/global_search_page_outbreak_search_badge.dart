part of '../screens/global_search_page.dart';

class _OutbreakSearchBadge extends StatelessWidget {
  const _OutbreakSearchBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty
        ? 'Published outbreak'
        : '${status[0].toUpperCase()}${status.substring(1)} outbreak';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
