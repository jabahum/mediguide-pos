part of '../screens/outbreak_document_screens.dart';

class _ReaderWarning extends StatelessWidget {
  const _ReaderWarning({
    required this.text,
    required this.icon,
    this.critical = false,
  });
  final String text;
  final IconData icon;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final color = critical ? Colors.red : Colors.orange;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.shade700),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
