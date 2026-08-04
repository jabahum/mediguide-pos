import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/utils/app_spacing.dart';

import '../../data/models/ai_context.dart';
import '../../data/models/rag_answer.dart';
import 'ai_assistant_controller.dart';

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
    final controller = ref.watch(
      aiAssistantControllerProvider(_initialContext),
    );
    final cs = context.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        backgroundColor: cs.surface,
        elevation: 0,
        title: Builder(
          builder: (context) {
            final currentContext = controller.currentContext;

            return Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: cs.primary,
                    size: 20,
                  ),
                ),

                AppSpacing.sm.gap,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentContext != null
                            ? currentContext.title
                            : AppTranslationKey.aiChatAssistant.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentContext != null
                            ? 'Context-aware assistant'
                            : 'MediGuide clinical assistant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Builder(
        builder: (context) {
          final currentContext = controller.currentContext;

          return Column(
            children: [
              if (currentContext != null)
                _AssistantContextBanner(
                  title: currentContext.title,
                  onClear: controller.clearContext,
                ),
              if (controller.errorMessage != null)
                _AssistantErrorBanner(
                  message: controller.errorMessage!,
                  isRetrying: controller.isLoading,
                  onRetry: controller.retryLastRequest,
                ),
              if (controller.latestCitations.isNotEmpty)
                _SourcesPanel(citations: controller.latestCitations),

              Expanded(
                child: AiChatWidget(
                  currentUser: controller.currentUser,
                  aiUser: controller.aiUser,
                  controller: controller.chatController,
                  loadingConfig: LoadingConfig(isLoading: controller.isLoading),
                  quickReplyOptions: QuickReplyOptions(
                    textStyle: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  welcomeMessageConfig: WelcomeMessageConfig(
                    titleStyle: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimaryContainer,
                      height: 1.35,
                    ),
                    containerDecoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    title: controller.contextualWelcomeMessage.isNotEmpty
                        ? controller.contextualWelcomeMessage
                        : 'Hello! I’m your MediGuide AI assistant. I can help with medical questions, drug information, clinical guidelines, and health-related queries. How can I assist you today?',
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
                    materialPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    containerPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: cs.surface,
    );
  }
}

class _AssistantErrorBanner extends StatelessWidget {
  const _AssistantErrorBanner({
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, color: cs.onErrorContainer, size: 18),
          AppSpacing.sm.gap,
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: cs.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: isRetrying ? null : onRetry,
            child: Text(isRetrying ? 'Retrying…' : 'Retry'),
          ),
        ],
      ),
    );
  }
}

class _SourcesPanel extends StatelessWidget {
  const _SourcesPanel({required this.citations});

  final List<RagCitation> citations;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ExpansionTile(
        dense: true,
        leading: const Icon(LucideIcons.bookOpenCheck, size: 18),
        title: Text(
          '${citations.length} approved source${citations.length == 1 ? '' : 's'}',
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          for (var index = 0; index < citations.length; index++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 12,
                child: Text(
                  '${index + 1}',
                  style: context.textTheme.labelSmall,
                ),
              ),
              title: Text(citations[index].displayLabel),
            ),
        ],
      ),
    );
  }
}

class _AssistantContextBanner extends StatelessWidget {
  final String title;
  final VoidCallback onClear;

  const _AssistantContextBanner({required this.title, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.fileText, color: cs.secondary, size: 20),
          ),

          AppSpacing.sm.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current context',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSecondaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onClear,
            tooltip: 'Clear context',
            icon: Icon(LucideIcons.x, color: cs.onSecondaryContainer, size: 18),
          ),
        ],
      ),
    );
  }
}
