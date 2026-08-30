import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';

import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/ai_assistant/data/models/rag_answer.dart';
import 'package:user_app/features/ai_assistant/presentation/controllers/ai_assistant_controller.dart';

part '../widgets/ai_assistant_page_assistant_menu_action.dart';
part '../widgets/ai_assistant_page_assistant_top_context.dart';
part '../widgets/ai_assistant_page_assistant_error_banner.dart';
part '../widgets/ai_assistant_page_sources_strip.dart';
part '../widgets/ai_assistant_page_citation_tile.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  AiContext? _initialContext;

  @override
  void initState() {
    super.initState();

    final arguments = widget.arguments;

    if (arguments is Map && arguments['aiContext'] is Map) {
      try {
        _initialContext = AiContext.fromJson(
          Map<String, dynamic>.from(arguments['aiContext'] as Map),
        );
      } catch (_) {
        _initialContext = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = aiAssistantControllerProvider(_initialContext);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

    final colors = Theme.of(context).colorScheme;

    final currentContext = state.currentContext;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentContext != null
                  ? currentContext.title
                  : 'MediGuide Assistant',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              currentContext != null
                  ? 'Using guideline context'
                  : 'Clinical knowledge assistant',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Assistant history',
            onPressed: () {
              context.push(AppRoutes.chatList);
            },
            icon: const Icon(LucideIcons.history),
          ),
          PopupMenuButton<_AssistantMenuAction>(
            tooltip: 'Assistant options',
            onSelected: (action) {
              switch (action) {
                case _AssistantMenuAction.clearContext:
                  controller.clearContext();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _AssistantMenuAction.clearContext,
                enabled: currentContext != null,
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(LucideIcons.fileX2),
                  title: Text('Clear guideline context'),
                ),
              ),
            ],
          ),
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: Column(
        children: [
          // =================================================================
          // SAFETY + CONTEXT
          // =================================================================
          _AssistantTopContext(
            currentContext: currentContext,
            onClearContext: controller.clearContext,
          ),

          // =================================================================
          // ERROR
          // =================================================================
          if (state.errorMessage != null)
            _AssistantErrorBanner(
              message: state.errorMessage!,
              isRetrying: state.isLoading,
              onRetry: () {
                controller.retryLastRequest();
              },
            ),

          // =================================================================
          // SOURCES
          // =================================================================
          if (state.latestCitations.isNotEmpty)
            _SourcesStrip(
              citations: state.latestCitations,
              onCitation: (citation) {
                _openCitation(context, citation);
              },
            ),

          // =================================================================
          // CHAT
          // =================================================================
          Expanded(
            child: AiChatWidget(
              currentUser: controller.currentUser,
              aiUser: controller.aiUser,
              controller: controller.chatController,

              loadingConfig: LoadingConfig(isLoading: state.isLoading),

              quickReplyOptions: QuickReplyOptions(
                textStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),

              welcomeMessageConfig: WelcomeMessageConfig(
                title: state.contextualWelcomeMessage.isNotEmpty
                    ? state.contextualWelcomeMessage
                    : 'Ask about clinical guidance, medicines, '
                          'calculators, terminology or MediGuide content.',
                titleStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  height: 1.4,
                ),
                containerDecoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outlineVariant),
                ),
              ),

              onSendMessage: controller.handleSendMessage,

              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),

              inputOptions: InputOptions(
                sendOnEnter: true,
                sendButtonIcon: LucideIcons.send,
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                materialPadding: EdgeInsets.zero,
                containerPadding: EdgeInsets.zero,
                decoration: InputDecoration(
                  hintText: currentContext != null
                      ? 'Ask about this guideline...'
                      : 'Ask MediGuide...',
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.primary, width: 1.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCitation(BuildContext context, RagCitation citation) {
    if (citation.guidelineId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This source does not include a navigable guideline.'),
        ),
      );

      return;
    }

    final base = AppRoutes.readPublicGuideline(citation.guidelineId);

    final sectionId = citation.sectionId.trim();

    final uri = sectionId.isEmpty
        ? base
        : '$base?section=${Uri.encodeQueryComponent(sectionId)}';

    context.push(uri);
  }
}
