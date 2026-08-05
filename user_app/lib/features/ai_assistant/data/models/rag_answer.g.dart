// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rag_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RagAnswer _$RagAnswerFromJson(Map<String, dynamic> json) => _RagAnswer(
  answer: json['answer'] as String? ?? '',
  citations:
      (json['citations'] as List<dynamic>?)
          ?.map((e) => RagCitation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  sessionId: json['session_id'] as String? ?? '',
);

Map<String, dynamic> _$RagAnswerToJson(_RagAnswer instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'citations': instance.citations.map((e) => e.toJson()).toList(),
      'session_id': instance.sessionId,
    };

_RagCitation _$RagCitationFromJson(Map<String, dynamic> json) => _RagCitation(
  chunkId: json['chunk_id'] as String? ?? '',
  title: json['title'] as String? ?? '',
  sourceName: json['source_name'] as String? ?? '',
  sourceVersion: json['source_version'] as String? ?? '',
  pageStart: (json['page_start'] as num?)?.toInt(),
  pageEnd: (json['page_end'] as num?)?.toInt(),
);

Map<String, dynamic> _$RagCitationToJson(_RagCitation instance) =>
    <String, dynamic>{
      'chunk_id': instance.chunkId,
      'title': instance.title,
      'source_name': instance.sourceName,
      'source_version': instance.sourceVersion,
      'page_start': instance.pageStart,
      'page_end': instance.pageEnd,
    };
