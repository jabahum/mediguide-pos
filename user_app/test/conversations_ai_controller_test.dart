import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/ai_assistant/data/models/rag_answer.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';
import 'package:user_app/features/ai_assistant/data/repositories/rag_repository.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/ai_assistant/presentation/controllers/ai_assistant_controller.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_interface_controller.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_list_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

final class ConversationSessionStore implements AuthSessionStore {
  @override
  User? currentUser = _user('user-1', 'Current User');

  @override
  Future<bool> clearUser() async => true;

  @override
  Future<bool> saveUser(User user) async {
    currentUser = user;
    return true;
  }
}

class ConversationAiApi extends BackendApiService {
  String? lastPath;
  String? lastMethod;
  Map<String, dynamic>? lastBody;
  int usageWrites = 0;

  @override
  bool get isAuthenticated => true;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    lastPath = path;
    lastMethod = method;
    lastBody = body;

    if (path == '/api/v2/me') {
      return {
        'data': {
          'id': 'user-1',
          'name': 'Current User',
          'email': 'user-1@example.test',
        },
      };
    }

    if (path == '/api/v2/conversations' && method == 'POST') {
      return {
        'data': {
          'id': 'conversation-1',
          'participant1_user_id': 'user-1',
          'participant2_user_id': 'user-2',
          'participant1_name': 'Current User',
          'participant2_name': 'Dr Other',
          'last_activity': '2026-01-01T00:00:00Z',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      };
    }
    if (path == '/api/v2/conversations/conversation-1/messages' &&
        method == 'GET') {
      return {
        'data': {
          'items': [_message('message-1', 'Welcome')],
          'page': 1,
          'per_page': 100,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    if (path == '/api/v2/conversations/conversation-1/messages' &&
        method == 'POST') {
      return {'data': _message('message-2', body?['content'] as String)};
    }
    if (path == '/api/v2/usage/ai') {
      usageWrites++;
      return {'data': <String, dynamic>{}};
    }
    throw StateError('Unexpected request: $method $path');
  }

  static Map<String, dynamic> _message(String id, String content) => {
    'id': id,
    'conversation_id': 'conversation-1',
    'sender_user_id': 'user-2',
    'sender_name': 'Dr Other',
    'content': content,
    'message_type': 'text',
    'attachments': <String>[],
    'read_by': <String, dynamic>{},
    'reactions': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };
}

class FakeRagAssistant implements RagAssistant {
  String? lastMessage;
  int resetCount = 0;

  @override
  String? get sessionId => 'session-1';

  @override
  void resetSession() {
    resetCount++;
  }

  @override
  Future<RagAnswer> ask({
    required String question,
    String? country,
    String? programArea,
  }) async {
    lastMessage = question;
    return const RagAnswer(
      answer: 'Use the clinical guideline and professional judgment.',
      sessionId: 'session-1',
      citations: [
        RagCitation(
          chunkId: 'chunk-1',
          title: 'Uganda Clinical Guidelines',
          sourceName: 'Ministry of Health',
          sourceVersion: '2023',
          pageStart: 42,
          pageEnd: 43,
        ),
      ],
    );
  }
}

User _user(String id, String name) =>
    User(id: id, name: name, email: '$id@example.test');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerFor(ConversationAiApi api) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        backendApiServiceProvider.overrideWithValue(api),
        authSessionStoreProvider.overrideWithValue(ConversationSessionStore()),
        sharedPreferencesProvider.overrideWithValue(preferences),
        conversationRepositoryProvider.overrideWithValue(
          ConversationRepository(api),
        ),
      ],
    );
    await container.read(authControllerProvider.future);
    return container;
  }

  test(
    'conversation catalogue owns filter state and authenticated identity',
    () async {
      final container = await containerFor(ConversationAiApi());
      addTearDown(container.dispose);
      container.listen(chatListControllerProvider, (_, _) {});
      final controller = container.read(chatListControllerProvider.notifier);

      controller.setSearchQuery('doctor');
      controller.setRecentOnly(true);
      controller.setVerifiedOnly(true);

      expect(
        container.read(chatListControllerProvider).hasActiveFilters,
        isTrue,
      );
      expect(controller.currentUserId, 'user-1');

      controller.clearAllFilters();
      expect(
        container.read(chatListControllerProvider).hasActiveFilters,
        isFalse,
      );
    },
  );

  test(
    'chat notifier initializes, polls, and sends through typed routes',
    () async {
      final api = ConversationAiApi();
      final container = await containerFor(api);
      addTearDown(container.dispose);
      final provider = chatInterfaceControllerProvider(
        _user('user-2', 'Dr Other'),
      );
      container.listen(provider, (_, _) {});
      final controller = container.read(provider.notifier);
      await controller.findOrCreateConversation();
      var state = container.read(provider);

      expect(state.conversationId, 'conversation-1');
      expect(state.messages.single.content, 'Welcome');
      expect(state.isConnected, isTrue);

      final sent = await controller.sendTextMessage('Hello doctor');
      expect(sent, isTrue);
      state = container.read(provider);
      expect(state.messages.last.content, 'Hello doctor');
      expect(api.lastPath, '/api/v2/conversations/conversation-1/messages');
      expect(api.lastBody?.containsKey('sender_user_id'), isFalse);
    },
  );

  test(
    'assistant applies route context and records owner-safe usage',
    () async {
      final api = ConversationAiApi();
      final rag = FakeRagAssistant();
      final context = AiContext.guideline(
        title: 'Hypertension',
        content: 'Assess blood pressure and cardiovascular risk.',
        guidelineId: 'guideline-1',
      );
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final provider = aiAssistantControllerProvider(context);
      final scoped = ProviderContainer(
        overrides: [
          backendApiServiceProvider.overrideWithValue(api),
          authSessionStoreProvider.overrideWithValue(
            ConversationSessionStore(),
          ),
          sharedPreferencesProvider.overrideWithValue(preferences),
          ragRepositoryProvider.overrideWithValue(rag),
          aiContextServiceProvider.overrideWithValue(AiContextService()),
          usageRepositoryProvider.overrideWithValue(UsageRepository(api)),
        ],
      );
      addTearDown(scoped.dispose);
      await scoped.read(authControllerProvider.future);
      scoped.listen(provider, (_, _) {});
      scoped.read(provider);
      final controller = scoped.read(provider.notifier);

      await controller.handleSendMessage(
        ChatMessage(
          text: 'What should I assess?',
          user: controller.currentUser,
          createdAt: DateTime(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(rag.lastMessage, contains('Hypertension'));
      var state = scoped.read(provider);
      expect(state.conversationHistory, hasLength(2));
      expect(state.latestCitations.single.chunkId, 'chunk-1');
      expect(state.isLoading, isFalse);
      expect(api.usageWrites, 1);
      expect(api.lastBody?.containsKey('user_id'), isFalse);

      controller.clearContext();
      state = scoped.read(provider);
      expect(state.currentContext, isNull);
    },
  );
}
