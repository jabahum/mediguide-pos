import 'package:freezed_annotation/freezed_annotation.dart';

part 'rag_answer.freezed.dart';
part 'rag_answer.g.dart';

@freezed
abstract class RagAnswer with _$RagAnswer {
  const RagAnswer._();

  @JsonSerializable(explicitToJson: true)
  const factory RagAnswer({
    @Default('') String answer,
    @Default([]) List<RagCitation> citations,
    @JsonKey(name: 'session_id') @Default('') String sessionId,
  }) = _RagAnswer;

  factory RagAnswer.fromJson(Map<String, dynamic> json) =>
      _$RagAnswerFromJson(json);

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

@freezed
abstract class RagCitation with _$RagCitation {
  const RagCitation._();

  const factory RagCitation({
    @JsonKey(name: 'chunk_id') @Default('') String chunkId,
    @Default('') String title,
    @JsonKey(name: 'source_name') @Default('') String sourceName,
    @JsonKey(name: 'source_version') @Default('') String sourceVersion,
    @JsonKey(name: 'page_start') int? pageStart,
    @JsonKey(name: 'page_end') int? pageEnd,
  }) = _RagCitation;

  factory RagCitation.fromJson(Map<String, dynamic> json) =>
      _$RagCitationFromJson(json);

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
