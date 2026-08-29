import 'package:shared_preferences/shared_preferences.dart';

import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';
import 'package:user_app/features/ai_assistant/data/models/rag_answer.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/constants/app_constants.dart';

abstract interface class RagAssistant {
  String? get sessionId;

  void resetSession();

  Future<RagAnswer> ask({
    required String question,
    String? country,
    String? programArea,
    bool authenticated = false,
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
    bool authenticated = false,
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
    final endpoint = authenticated
        ? '/api/v2/chat/ask'
        : '/api/public/assistant/ask';
    final envelope = await _api
        .requestJsonWithTimeout(
          endpoint,
          method: 'POST',
          body: request.toJson(),
          includeAuth: authenticated,
          receiveTimeout: const Duration(seconds: 130),
        )
        .timeout(const Duration(seconds: 135));
    final data = envelope['data'];
    if (data is! Map) {
      throw const FormatException('RAG response is missing its data object');
    }

    final response = RagAnswer.fromJson(Map<String, dynamic>.from(data));
    final answer = response.answer.trim();
    if (answer.isEmpty) {
      throw const FormatException('RAG response contains an empty answer');
    }

    final returnedSession = response.sessionId.trim();
    if (returnedSession.isNotEmpty) _sessionId = returnedSession;
    return response.copyWith(
      answer: answer,
      sessionId: returnedSession,
      citations: response.citations
          .map(
            (citation) => citation.copyWith(
              chunkId: citation.chunkId.trim(),
              guidelineId: citation.guidelineId.trim(),
              sectionId: citation.sectionId.trim(),
              blockId: citation.blockId.trim(),
              title: citation.title.trim(),
              sourceName: citation.sourceName.trim(),
              sourceVersion: citation.sourceVersion.trim(),
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
