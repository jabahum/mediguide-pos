part of '../screens/outbreak_document_screens.dart';

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
