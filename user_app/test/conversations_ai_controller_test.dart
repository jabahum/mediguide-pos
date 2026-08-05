import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
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

class ConversationAiApi extends BackendApiService {
  String? lastPath;
  String? lastMethod;
  Map<String, dynamic>? lastBody;
  int usageWrites = 0;

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

  test(
    'conversation catalogue owns filter state and authenticated identity',
    () {
      final controller = ChatListController(
        ConversationRepository(ConversationAiApi()),
        currentUserId: 'user-1',
      );
      addTearDown(controller.dispose);

      controller.setSearchQuery('doctor');
      controller.setRecentOnly(true);
      controller.setVerifiedOnly(true);

      expect(controller.hasActiveFilters, isTrue);
      expect(controller.currentUserId, 'user-1');

      controller.clearAllFilters();
      expect(controller.hasActiveFilters, isFalse);
    },
  );

  test(
    'chat notifier initializes, polls, and sends through typed routes',
    () async {
      final api = ConversationAiApi();
      final controller = ChatInterfaceController(
        ConversationRepository(api),
        otherUser: _user('user-2', 'Dr Other'),
        currentUserId: 'user-1',
      );
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.conversationId, 'conversation-1');
      expect(controller.messages.single.content, 'Welcome');
      expect(controller.isConnected, isTrue);

      final sent = await controller.sendTextMessage('Hello doctor');
      expect(sent, isTrue);
      expect(controller.messages.last.content, 'Hello doctor');
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
      final controller = AiAssistantController(
        ragAssistant: rag,
        contextService: AiContextService(),
        usageRepository: UsageRepository(api),
        currentUser: _user('user-1', 'Clinician'),
        initialContext: context,
      );
      addTearDown(controller.dispose);

      await controller.handleSendMessage(
        ChatMessage(
          text: 'What should I assess?',
          user: controller.currentUser,
          createdAt: DateTime(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(rag.lastMessage, contains('Hypertension'));
      expect(controller.conversationHistory, hasLength(2));
      expect(controller.latestCitations.single.chunkId, 'chunk-1');
      expect(controller.isLoading, isFalse);
      expect(api.usageWrites, 1);
      expect(api.lastBody?.containsKey('user_id'), isFalse);

      controller.clearContext();
      expect(controller.currentContext, isNull);
    },
  );
}
