import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../utils/preference_utils.dart';
import 'auth_service.dart';
import 'backend_api_service.dart';

class OpenAiService {
  OpenAiService([BackendApiService? backend, AuthService? auth])
    : _backend = backend,
      _auth = auth;

  final BackendApiService? _backend;
  final AuthService? _auth;
  BackendApiService get _api =>
      _backend ?? (throw StateError('BackendApiService was not provided'));
  AuthService get _authService =>
      _auth ?? (throw StateError('AuthService was not provided'));

  String? _sessionId;

  bool get isConfigured => _api.isAuthenticated;
  String? get sessionId => _sessionId;

  Future<OpenAiService> init() async {
    return this;
  }

  void resetSession() {
    _sessionId = null;
  }

  Future<String> createChatCompletion({
    required String userMessage,
    List<String>? conversationHistory,
    String? customInstructions,
  }) async {
    try {
      if (!isConfigured) {
        return _getFallbackResponse(userMessage);
      }

      final response = await http.post(
        Uri.parse('$mediguideApiBaseUrl/api/v2/chat/ask'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_api.accessToken}',
        },
        body: jsonEncode({
          'question': _buildQuestion(
            userMessage: userMessage,
            customInstructions: customInstructions,
          ),
          'language': _resolveLanguage(),
          'country': _resolveCountry(),
          'program_area': '',
          if (_sessionId != null && _sessionId!.isNotEmpty)
            'session_id': _sessionId,
        }),
      );

      final decoded = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode >= 400 || decoded['success'] == false) {
        throw Exception(
          Common.parseApiError(decoded['error'] ?? response.body),
        );
      }

      final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
      final answer = data['answer']?.toString().trim() ?? '';
      _sessionId = data['session_id']?.toString();

      if (answer.isEmpty) {
        throw Exception('Empty response from chat service');
      }

      return answer;
    } catch (e) {
      Common.quickToast(
        title: 'AI Response Error',
        description: 'Failed to get AI response: ${e.toString()}',
      );
      return _getFallbackResponse(userMessage);
    }
  }

  String _buildQuestion({
    required String userMessage,
    String? customInstructions,
  }) {
    final trimmedMessage = userMessage.trim();
    final trimmedInstructions = customInstructions?.trim() ?? '';

    if (trimmedInstructions.isEmpty) {
      return trimmedMessage;
    }

    return '''
Use this in-app reference context when it is relevant:
$trimmedInstructions

User question:
$trimmedMessage
'''
        .trim();
  }

  String _resolveLanguage() {
    final language = PreferenceUtils.getString(
      SharedPreferencesKeys.language,
      'en',
    );
    return language.isEmpty ? 'en' : language;
  }

  String _resolveCountry() {
    final userCountry = _authService.currentUser.value?.country.trim() ?? '';
    return userCountry.isEmpty ? 'UG' : userCountry;
  }

  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    final notConfigured = !isConfigured;

    if (lowerMessage.contains('emergency') || lowerMessage.contains('urgent')) {
      return '''
🚨 **MEDICAL EMERGENCY**

If this is a life-threatening emergency, please:
1. Call emergency services immediately
2. Seek immediate medical attention
3. Contact the nearest healthcare facility

MediGuide AI is currently ${notConfigured ? 'not available because you are not signed in' : 'unavailable'}, but you can:
• Browse our Guidelines section for clinical protocols
• Check the Drug Index for medication information
• Use our medical calculators in Tools section
• Connect with Consultants for expert advice

**Disclaimer**: This is not a substitute for emergency medical care.
''';
    }

    if (lowerMessage.contains('drug') || lowerMessage.contains('medicine')) {
      return '''
💊 **Drug Information**

MediGuide AI is temporarily ${notConfigured ? 'not available because you are not signed in' : 'unavailable'}. For medication information:

• **Drug Index**: Browse our comprehensive drug database
• **Interactions**: Check drug interactions and contraindications
• **Dosages**: Reference dosing guidelines and calculations
• **Side Effects**: Review adverse reactions and monitoring

Navigate to the Drug Index section or consult with our medical experts.
''';
    }

    if (lowerMessage.contains('guideline') ||
        lowerMessage.contains('protocol')) {
      return '''
📋 **Clinical Guidelines**

MediGuide AI is temporarily ${notConfigured ? 'not available because you are not signed in' : 'unavailable'}. For clinical guidance:

• **Guidelines Section**: Access evidence-based treatment protocols
• **Clinical Pathways**: Follow standardized care procedures
• **Best Practices**: Review recommended clinical approaches
• **Updates**: Check for latest guideline revisions

Navigate to the Guidelines section for comprehensive protocols.
''';
    }

    return '''
🤖 **MediGuide AI ${notConfigured ? 'Unavailable' : 'Temporarily Unavailable'}**

${notConfigured ? 'Sign in to use the backend chat assistant.' : 'The AI assistant is currently experiencing difficulties.'}

**Available Resources:**
• **Drug Index**: Comprehensive medication information
• **Guidelines**: Clinical treatment protocols
• **Tools**: Medical calculators and decision aids
• **Consultants**: Connect with medical experts

**For urgent medical questions**: Please consult with healthcare professionals or use our Consultants feature.

**Disclaimer**: Always verify information with qualified healthcare providers.
''';
  }

  List<String> getContextualSuggestions(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('drug') || lowerMessage.contains('medicine')) {
      return [
        'Check drug interactions',
        'View dosing guidelines',
        'Browse Drug Index',
        'Calculate pediatric doses',
      ];
    }

    if (lowerMessage.contains('guideline') ||
        lowerMessage.contains('protocol')) {
      return [
        'Search treatment guidelines',
        'View emergency protocols',
        'Access clinical pathways',
        'Check latest updates',
      ];
    }

    if (lowerMessage.contains('calculator') || lowerMessage.contains('tool')) {
      return [
        'BMI calculator',
        'Dosage calculator',
        'Risk assessment tools',
        'Clinical checklists',
      ];
    }

    return [
      'Search medical guidelines',
      'Check drug information',
      'Use medical calculators',
      'Consult with experts',
    ];
  }
}
