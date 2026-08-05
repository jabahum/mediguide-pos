final class RagAnswer {
  const RagAnswer({
    required this.answer,
    required this.citations,
    required this.sessionId,
  });

  final String answer;
  final List<RagCitation> citations;
  final String sessionId;

  String get answerWithSources {
    if (citations.isEmpty) return answer;
    final sources = citations
        .asMap()
        .entries
        .map((entry) => '[${entry.key + 1}] ${entry.value.displayLabel}')
        .join('\n');
    return '$answer\n\n**Sources**\n$sources';
  }
}

final class RagCitation {
  const RagCitation({
    required this.chunkId,
    required this.title,
    required this.sourceName,
    required this.sourceVersion,
    this.pageStart,
    this.pageEnd,
  });

  final String chunkId;
  final String title;
  final String sourceName;
  final String sourceVersion;
  final int? pageStart;
  final int? pageEnd;

  String get displayLabel {
    final name = title.trim().isNotEmpty
        ? title.trim()
        : sourceName.trim().isNotEmpty
        ? sourceName.trim()
        : 'Approved guideline';
    final details = <String>[
      if (sourceName.trim().isNotEmpty && sourceName.trim() != name)
        sourceName.trim(),
      if (sourceVersion.trim().isNotEmpty) sourceVersion.trim(),
      if (pageStart != null && pageEnd != null && pageEnd != pageStart)
        'pages $pageStart–$pageEnd'
      else if (pageStart != null)
        'page $pageStart',
    ];
    return details.isEmpty ? name : '$name — ${details.join(', ')}';
  }
}
