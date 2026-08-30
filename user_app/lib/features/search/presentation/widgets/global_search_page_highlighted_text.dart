part of '../screens/global_search_page.dart';

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.maxLines,
    this.style,
  });

  final String text;
  final String query;
  final int? maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = query.trim();

    final normal = style ?? DefaultTextStyle.of(context).style;

    if (trimmedQuery.isEmpty) {
      return Text(
        text,
        style: normal,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final index = text.toLowerCase().indexOf(trimmedQuery.toLowerCase());

    if (index < 0) {
      return Text(
        text,
        style: normal,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final matchEnd = index + trimmedQuery.length;

    return Text.rich(
      TextSpan(
        style: normal,
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index)),

          TextSpan(
            text: text.substring(index, matchEnd),
            style: normal.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          if (matchEnd < text.length) TextSpan(text: text.substring(matchEnd)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// ===========================================================================
/// EMPTY / ERROR / LOADING STATE
/// ===========================================================================
