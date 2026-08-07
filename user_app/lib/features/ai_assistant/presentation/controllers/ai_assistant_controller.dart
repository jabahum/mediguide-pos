import 'dart:async';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/ai_assistant/data/models/rag_answer.dart';
import 'package:user_app/features/ai_assistant/data/repositories/rag_repository.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';

import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';

part 'ai_assistant_controller.g.dart';

class AiAssistantState {
  const AiAssistantState({
    this.isLoading = false,
    this.isTyping = false,
    this.currentContext,
    this.contextualWelcomeMessage = '',
    this.contextualExampleQuestions = const [],
    this.latestCitations = const [],
    this.errorMessage,
    this.failedUserMessage,
    this.conversationHistory = const [],
  });

  final bool isLoading;
  final bool isTyping;

  final AiContext? currentContext;

  final String contextualWelcomeMessage;
  final List<String> contextualExampleQuestions;

  final List<RagCitation> latestCitations;

  final String? errorMessage;
  final String? failedUserMessage;

  final List<String> conversationHistory;

  AiAssistantState copyWith({
    bool? isLoading,
    bool? isTyping,
    AiContext? currentContext,
    bool clearContext = false,
    String? contextualWelcomeMessage,
    List<String>? contextualExampleQuestions,
    List<RagCitation>? latestCitations,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? failedUserMessage,
    bool clearFailedUserMessage = false,
    List<String>? conversationHistory,
  }) {
    return AiAssistantState(
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      currentContext: clearContext
          ? null
          : currentContext ?? this.currentContext,
      contextualWelcomeMessage:
          contextualWelcomeMessage ?? this.contextualWelcomeMessage,
      contextualExampleQuestions:
          contextualExampleQuestions ?? this.contextualExampleQuestions,
      latestCitations: latestCitations ?? this.latestCitations,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      failedUserMessage: clearFailedUserMessage
          ? null
          : failedUserMessage ?? this.failedUserMessage,
      conversationHistory: conversationHistory ?? this.conversationHistory,
    );
  }
}

@riverpod
class AiAssistantController extends _$AiAssistantController {
  late final RagAssistant _ragAssistant;
  late final AiContextService _contextService;
  late final UsageRepository _usageRepository;
  User? _domainUser;

  late final ChatMessagesController chatController;
  late final ChatUser currentUser;
  late final ChatUser aiUser;

  @override
  AiAssistantState build(AiContext? initialContext) {
    _ragAssistant = ref.read(ragRepositoryProvider);
    _contextService = ref.read(aiContextServiceProvider);
    _usageRepository = ref.read(usageRepositoryProvider);

    _domainUser = ref.read(authControllerProvider).valueOrNull?.user;

    currentUser = ChatUser(
      id: _domainUser?.id ?? 'user',
      firstName: _domainUser?.name ?? 'You',
    );

    aiUser = ChatUser(id: 'ai_assistant', firstName: 'MediGuide AI');

    chatController = ChatMessagesController();

    _ragAssistant.resetSession();

    ref.onDispose(() {
      _ragAssistant.resetSession();
      chatController.dispose();
    });

    final contextualContent = _buildContextualContent(initialContext);

    return AiAssistantState(
      currentContext: initialContext,
      contextualWelcomeMessage: contextualContent.welcomeMessage,
      contextualExampleQuestions: contextualContent.exampleQuestions,
    );
  }

  void clearContext() {
    state = state.copyWith(
      clearContext: true,
      contextualWelcomeMessage: '',
      contextualExampleQuestions: const [],
    );
  }

  void setContext(AiContext? context) {
    if (context == null) {
      clearContext();
      return;
    }

    final contextualContent = _buildContextualContent(context);

    state = state.copyWith(
      currentContext: context,
      contextualWelcomeMessage: contextualContent.welcomeMessage,
      contextualExampleQuestions: contextualContent.exampleQuestions,
    );
  }

  _ContextualContent _buildContextualContent(AiContext? context) {
    if (context == null) {
      return const _ContextualContent();
    }

    try {
      return _ContextualContent(
        welcomeMessage: _contextService.generateWelcomeMessage(context),
        exampleQuestions: _contextService.generateExampleQuestions(context),
      );
    } catch (_) {
      return const _ContextualContent();
    }
  }

  Future<void> handleSendMessage(ChatMessage message) async {
    if (state.isLoading) return;

    final userMessage = message.text.trim();

    if (userMessage.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      isTyping: true,
      clearErrorMessage: true,
      clearFailedUserMessage: true,
    );

    try {
      chatController.addMessage(message);

      state = state.copyWith(
        conversationHistory: [...state.conversationHistory, userMessage],
      );

      await _handleAiResponse(userMessage);
    } catch (error) {
      final errorMessage = _messageFor(error);

      state = state.copyWith(
        errorMessage: errorMessage,
        failedUserMessage: userMessage,
      );

      _addAssistantMessage(
        'I could not reach the approved-guideline assistant. '
        '$errorMessage No clinical answer was generated.',
      );

      _showError(errorMessage);
    } finally {
      state = state.copyWith(isLoading: false, isTyping: false);
    }
  }

  Future<void> _handleAiResponse(String userMessage) async {
    var requestMessage = userMessage;

    final context = state.currentContext;

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

    state = state.copyWith(
      latestCitations: response.citations,
      conversationHistory: [...state.conversationHistory, response.answer],
    );

    _addAssistantMessage(response.answerWithSources);

    unawaited(_trackUsage());
  }

  Future<void> retryLastRequest() async {
    final message = state.failedUserMessage;

    if (message == null || state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isTyping: true,
      clearErrorMessage: true,
    );

    try {
      await _handleAiResponse(message);

      state = state.copyWith(clearFailedUserMessage: true);
    } catch (error) {
      final errorMessage = _messageFor(error);

      state = state.copyWith(errorMessage: errorMessage);

      _showError(errorMessage);
    } finally {
      state = state.copyWith(isLoading: false, isTyping: false);
    }
  }

  void _addAssistantMessage(String text) {
    chatController.addMessage(
      ChatMessage(text: text, user: aiUser, createdAt: DateTime.now()),
    );
  }

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) return;

    AppMessage.error(context, message);
  }

  String _messageFor(Object error) {
    if (error is TimeoutException) {
      return 'The assistant took too long to respond. Please retry.';
    }

    if (error is BackendApiException) {
      if (error.isRateLimited) {
        return error.toString();
      }

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
    final metadata = state.currentContext?.metadata;

    return metadata?['program_area']?.toString().trim() ??
        metadata?['programArea']?.toString().trim() ??
        '';
  }

  Future<void> _trackUsage() async {
    try {
      await _usageRepository.ai();
    } catch (_) {
      // Analytics must never interrupt the assistant.
    }
  }

  List<String> get defaultExampleQuestions => const [
    'What are the side effects of paracetamol?',
    'Show me hypertension treatment guidelines',
    'How do I calculate BMI?',
    'What are the symptoms of malaria?',
    'Emergency protocols for chest pain',
  ];

  List<String> get exampleQuestions {
    if (state.contextualExampleQuestions.isNotEmpty) {
      return List<String>.unmodifiable(state.contextualExampleQuestions);
    }

    return defaultExampleQuestions;
  }
}

class _ContextualContent {
  const _ContextualContent({
    this.welcomeMessage = '',
    this.exampleQuestions = const [],
  });

  final String welcomeMessage;
  final List<String> exampleQuestions;
}
