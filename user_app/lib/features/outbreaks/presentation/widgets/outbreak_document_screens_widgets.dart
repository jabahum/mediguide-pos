part of '../screens/outbreak_document_screens.dart';

class _ReaderChip extends StatelessWidget {
  const _ReaderChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Chip(avatar: Icon(icon, size: 16), label: Text(label)),
  );
}

class OutbreakUnsupportedFormatNotice extends StatelessWidget {
  const OutbreakUnsupportedFormatNotice({super.key});

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: const ListTile(
      leading: Icon(LucideIcons.fileWarning),
      title: Text('Inline preview unavailable'),
      subtitle: Text(
        'This format cannot be rendered safely in the app. Download or open the authoritative original instead.',
      ),
    ),
  );
}

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

class _SearchMatchPreview extends StatelessWidget {
  const _SearchMatchPreview({
    required this.source,
    required this.query,
    required this.offset,
  });
  final String source;
  final String query;
  final int offset;

  @override
  Widget build(BuildContext context) {
    final start = (offset - 55).clamp(0, source.length).toInt();
    final end = (offset + query.length + 55).clamp(0, source.length).toInt();
    final before = source.substring(start, offset);
    final matchEnd = (offset + query.length).clamp(0, source.length).toInt();
    final match = source.substring(offset, matchEnd);
    final after = source.substring(matchEnd, end);
    final style = Theme.of(context).textTheme.bodySmall;
    return Semantics(
      liveRegion: true,
      label: 'Current search match: $match',
      child: Container(
        width: double.infinity,
        color: Colors.amber.withValues(alpha: 0.14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text.rich(
          TextSpan(
            style: style,
            children: [
              TextSpan(text: start > 0 ? '…$before' : before),
              TextSpan(
                text: match,
                style: style?.copyWith(
                  fontWeight: FontWeight.w800,
                  backgroundColor: Colors.amber.shade300,
                ),
              ),
              TextSpan(text: end < source.length ? '$after…' : after),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
