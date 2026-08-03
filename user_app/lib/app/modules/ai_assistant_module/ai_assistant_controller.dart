import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ai_context.dart';
import '../../data/models/user.dart';
import '../../data/repositories/progress_usage_repository.dart';
import '../../data/services/ai_context_service.dart';
import '../../data/services/openai_service.dart';
import '../../features/auth/auth_controller.dart';
import '../../providers/core_providers.dart';
import '../../utils/common.dart';

final aiAssistantControllerProvider = ChangeNotifierProvider.autoDispose
    .family<AiAssistantController, AiContext?>((ref, initialContext) {
      return AiAssistantController(
        openAiService: ref.watch(openAiServiceProvider),
        contextService: ref.watch(aiContextServiceProvider),
        usageRepository: ref.watch(usageRepositoryProvider),
        currentUser: ref.watch(authControllerProvider).valueOrNull?.user,
        initialContext: initialContext,
      );
    });

class AiAssistantController extends ChangeNotifier {
  AiAssistantController({
    required OpenAiService openAiService,
    required AiContextService contextService,
    required UsageRepository usageRepository,
    required User? currentUser,
    AiContext? initialContext,
  }) : _openAiService = openAiService,
       _contextService = contextService,
       _usageRepository = usageRepository,
       currentContext = initialContext,
       currentUser = ChatUser(
         id: currentUser?.id ?? 'user',
         firstName: currentUser?.name ?? 'You',
       ),
       aiUser = ChatUser(id: 'ai_assistant', firstName: 'MediGuide AI') {
    _openAiService.resetSession();
    chatController = ChatMessagesController();
    _generateContextualContent();
  }

  final OpenAiService _openAiService;
  final AiContextService _contextService;
  final UsageRepository _usageRepository;
  late final ChatMessagesController chatController;

  bool isLoading = false;
  bool isTyping = false;
  final List<String> conversationHistory = [];
  final ChatUser currentUser;
  final ChatUser aiUser;
  AiContext? currentContext;
  String contextualWelcomeMessage = '';
  List<String> contextualExampleQuestions = [];
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _openAiService.resetSession();
    chatController.dispose();
    super.dispose();
  }

  void clearContext() {
    currentContext = null;
    contextualWelcomeMessage = '';
    contextualExampleQuestions = [];
    _notify();
  }

  void _generateContextualContent() {
    final context = currentContext;
    if (context == null) return;
    try {
      contextualWelcomeMessage = _contextService.generateWelcomeMessage(
        context,
      );
      contextualExampleQuestions = _contextService.generateExampleQuestions(
        context,
      );
    } catch (_) {
      contextualWelcomeMessage = '';
      contextualExampleQuestions = [];
    }
  }

  Future<void> handleSendMessage(ChatMessage message) async {
    if (isLoading) return;
    isLoading = true;
    isTyping = true;
    _notify();
    try {
      chatController.addMessage(message);
      conversationHistory.add(message.text);
      await _handleAiResponse(message.text);
    } catch (error) {
      Common.quickToast(
        title: 'Error',
        description: 'Failed to send message: $error',
      );
      await _handleFallbackResponse(message.text);
    } finally {
      isLoading = false;
      isTyping = false;
      _notify();
    }
  }

  Future<void> _handleAiResponse(String userMessage) async {
    try {
      var requestMessage = userMessage;
      final context = currentContext;
      if (context != null) {
        requestMessage = _contextService.buildContextQuestion(
          context,
          userMessage,
        );
      }

      final response = await _openAiService.createChatCompletion(
        userMessage: requestMessage,
        conversationHistory: conversationHistory.length > 10
            ? conversationHistory.sublist(conversationHistory.length - 10)
            : List<String>.of(conversationHistory),
      );
      chatController.addMessage(
        ChatMessage(text: response, user: aiUser, createdAt: DateTime.now()),
      );
      conversationHistory.add(response);
      unawaited(_trackUsage());
    } catch (_) {
      await _handleFallbackResponse(userMessage);
    }
  }

  Future<void> _handleFallbackResponse(String userMessage) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final response = _localFallbackResponse(userMessage);
    chatController.addMessage(
      ChatMessage(text: response, user: aiUser, createdAt: DateTime.now()),
    );
    conversationHistory.add(response);
    unawaited(_trackUsage());
  }

  String _localFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    if (message.contains('drug') || message.contains('medicine')) {
      return '💊 **Drug Information**\n\nBrowse the Drug Index for medication, dosage, interaction, and contraindication information. Always verify drug information with a qualified healthcare professional.';
    }
    if (message.contains('guideline') || message.contains('protocol')) {
      return '📋 **Clinical Guidelines**\n\nThe Guidelines section contains evidence-based treatment protocols. Use them together with clinical judgment and local policy.';
    }
    if (message.contains('calculator') || message.contains('tool')) {
      return '🧮 **Medical Tools**\n\nThe Tools section includes clinical calculators, decision tools, and checklists. Verify inputs and interpret results in the patient’s clinical context.';
    }
    if (message.contains('emergency') || message.contains('urgent')) {
      return '🚨 **MEDICAL EMERGENCY**\n\nCall emergency services and seek immediate medical attention. MediGuide is not a substitute for emergency medical care.';
    }
    return '🤖 **MediGuide AI Assistant**\n\nI can help you find drug information, clinical guidelines, medical tools, and consultants. Always confirm patient-specific decisions with a qualified healthcare professional.';
  }

  Future<void> _trackUsage() async {
    try {
      await _usageRepository.ai();
    } catch (_) {
      // Analytics must never interrupt the assistant interaction.
    }
  }

  List<String> get defaultExampleQuestions => const [
    'What are the side effects of paracetamol?',
    'Show me hypertension treatment guidelines',
    'How do I calculate BMI?',
    'What are the symptoms of malaria?',
    'Emergency protocols for chest pain',
  ];

  List<String> get exampleQuestions => contextualExampleQuestions.isNotEmpty
      ? List<String>.unmodifiable(contextualExampleQuestions)
      : defaultExampleQuestions;

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
