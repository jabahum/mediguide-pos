import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/ai_assistant/data/models/rag_answer.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';
import 'package:user_app/features/ai_assistant/data/repositories/rag_repository.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/utils/common.dart';

final aiAssistantControllerProvider = ChangeNotifierProvider.autoDispose
    .family<AiAssistantController, AiContext?>((ref, initialContext) {
      return AiAssistantController(
        ragAssistant: ref.watch(ragRepositoryProvider),
        contextService: ref.watch(aiContextServiceProvider),
        usageRepository: ref.watch(usageRepositoryProvider),
        currentUser: ref.watch(authControllerProvider).valueOrNull?.user,
        initialContext: initialContext,
      );
    });

class AiAssistantController extends ChangeNotifier {
  AiAssistantController({
    required RagAssistant ragAssistant,
    required AiContextService contextService,
    required UsageRepository usageRepository,
    required User? currentUser,
    AiContext? initialContext,
  }) : _ragAssistant = ragAssistant,
       _contextService = contextService,
       _usageRepository = usageRepository,
       _domainUser = currentUser,
       currentContext = initialContext,
       currentUser = ChatUser(
         id: currentUser?.id ?? 'user',
         firstName: currentUser?.name ?? 'You',
       ),
       aiUser = ChatUser(id: 'ai_assistant', firstName: 'MediGuide AI') {
    _ragAssistant.resetSession();
    chatController = ChatMessagesController();
    _generateContextualContent();
  }

  final RagAssistant _ragAssistant;
  final AiContextService _contextService;
  final UsageRepository _usageRepository;
  final User? _domainUser;
  late final ChatMessagesController chatController;

  bool isLoading = false;
  bool isTyping = false;
  final List<String> conversationHistory = [];
  final ChatUser currentUser;
  final ChatUser aiUser;
  AiContext? currentContext;
  String contextualWelcomeMessage = '';
  List<String> contextualExampleQuestions = [];
  List<RagCitation> latestCitations = const [];
  String? errorMessage;
  String? _failedUserMessage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _ragAssistant.resetSession();
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
    final userMessage = message.text.trim();
    if (userMessage.isEmpty) return;
    isLoading = true;
    isTyping = true;
    errorMessage = null;
    _failedUserMessage = null;
    _notify();
    try {
      chatController.addMessage(message);
      conversationHistory.add(userMessage);
      await _handleAiResponse(userMessage);
    } catch (error) {
      _failedUserMessage = userMessage;
      errorMessage = _messageFor(error);
      _addAssistantMessage(
        'I could not reach the approved-guideline assistant. '
        '${errorMessage!} No clinical answer was generated.',
      );
      Common.quickToast(
        title: 'Assistant unavailable',
        description: errorMessage,
      );
    } finally {
      isLoading = false;
      isTyping = false;
      _notify();
    }
  }

  Future<void> _handleAiResponse(String userMessage) async {
    var requestMessage = userMessage;
    final context = currentContext;
    if (context != null) {
      requestMessage = _contextService.buildContextQuestion(
        context,
        userMessage,
      );
    }
    final response = await _ragAssistant.ask(
      question: requestMessage,
      country: _country,
      programArea: _programArea,
    );
    latestCitations = response.citations;
    _addAssistantMessage(response.answerWithSources);
    conversationHistory.add(response.answer);
    unawaited(_trackUsage());
  }

  Future<void> retryLastRequest() async {
    final message = _failedUserMessage;
    if (message == null || isLoading) return;
    isLoading = true;
    isTyping = true;
    errorMessage = null;
    _notify();
    try {
      await _handleAiResponse(message);
      _failedUserMessage = null;
    } catch (error) {
      errorMessage = _messageFor(error);
      Common.quickToast(
        title: 'Assistant unavailable',
        description: errorMessage,
      );
    } finally {
      isLoading = false;
      isTyping = false;
      _notify();
    }
  }

  void _addAssistantMessage(String text) {
    chatController.addMessage(
      ChatMessage(text: text, user: aiUser, createdAt: DateTime.now()),
    );
  }

  String _messageFor(Object error) {
    if (error is TimeoutException) {
      return 'The assistant took too long to respond. Please retry.';
    }
    if (error is BackendApiException) {
      if (error.isRateLimited) return error.toString();
      if (error.statusCode == 401) {
        return 'Your session expired. Sign in again.';
      }
      if (error.statusCode == 403) {
        return 'Your account does not have permission to use the assistant.';
      }
      if (error.statusCode >= 500) {
        return 'The RAG service is temporarily unavailable. Please retry.';
      }
      return error.message;
    }
    return 'Check your connection and try again.';
  }

  String get _country {
    final value = _domainUser?.country.trim() ?? '';
    return value.isEmpty ? 'UG' : value;
  }

  String get _programArea {
    final metadata = currentContext?.metadata;
    return metadata?['program_area']?.toString().trim() ??
        metadata?['programArea']?.toString().trim() ??
        '';
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
