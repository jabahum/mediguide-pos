import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/generated/backend_contracts.dart';
import '../models/rag_answer.dart';
import '../services/backend_api_service.dart';
import '../../utils/constants.dart';

abstract interface class RagAssistant {
  String? get sessionId;

  void resetSession();

  Future<RagAnswer> ask({
    required String question,
    String? country,
    String? programArea,
  });
}

final class RagRepository implements RagAssistant {
  RagRepository(this._api, this._preferences);

  final BackendApiService _api;
  final SharedPreferences _preferences;
  String? _sessionId;

  @override
  String? get sessionId => _sessionId;

  @override
  void resetSession() => _sessionId = null;

  @override
  Future<RagAnswer> ask({
    required String question,
    String? country,
    String? programArea,
  }) async {
    final normalizedQuestion = question.trim();
    if (normalizedQuestion.isEmpty) {
      throw ArgumentError.value(question, 'question', 'Question is required');
    }

    final request = ServicesAskRequest.fromJson({
      'question': normalizedQuestion,
      'language': _language,
      'country': _normalizeCountry(country),
      'program_area': programArea?.trim() ?? '',
      if (_sessionId?.isNotEmpty == true) 'session_id': _sessionId,
    });
    final envelope = await _api
        .requestJson('/api/v2/chat/ask', method: 'POST', body: request.toJson())
        .timeout(const Duration(seconds: 130));
    final data = envelope['data'];
    if (data is! Map) {
      throw const FormatException('RAG response is missing its data object');
    }

    final response = ServicesAskResponse.fromJson(
      Map<String, dynamic>.from(data),
    );
    final answer = response.answer?.trim() ?? '';
    if (answer.isEmpty) {
      throw const FormatException('RAG response contains an empty answer');
    }

    final returnedSession = response.sessionId?.trim() ?? '';
    if (returnedSession.isNotEmpty) _sessionId = returnedSession;
    return RagAnswer(
      answer: answer,
      sessionId: returnedSession,
      citations: response.citations
          .map(
            (citation) => RagCitation(
              chunkId: citation.chunkId?.trim() ?? '',
              title: citation.title?.trim() ?? '',
              sourceName: citation.sourceName?.trim() ?? '',
              sourceVersion: citation.sourceVersion?.trim() ?? '',
              pageStart: citation.pageStart,
              pageEnd: citation.pageEnd,
            ),
          )
          .toList(growable: false),
    );
  }

  String get _language {
    final value =
        _preferences.getString(SharedPreferencesKeys.language)?.trim() ?? '';
    return value.isEmpty ? 'en' : value;
  }

  String _normalizeCountry(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'UG';
    if (normalized.length == 2) return normalized.toUpperCase();
    return switch (normalized.toLowerCase()) {
      'uganda' => 'UG',
      'kenya' => 'KE',
      'tanzania' => 'TZ',
      'rwanda' => 'RW',
      'burundi' => 'BI',
      'south sudan' => 'SS',
      _ => normalized,
    };
  }
}
