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

enum _AssistantMenuAction { clearContext }

// ===========================================================================
// TOP CONTEXT
// ===========================================================================

class _AssistantTopContext extends StatelessWidget {
  const _AssistantTopContext({
    required this.currentContext,
    required this.onClearContext,
  });

  final AiContext? currentContext;
  final VoidCallback onClearContext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===============================================================
            // SAFETY
            // ===============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldAlert, size: 17, color: colors.tertiary),

                AppSpacing.hGapSm,

                Expanded(
                  child: Text(
                    'Do not enter patient-identifiable information. '
                    'Verify clinical answers against cited sources and professional judgement.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),

            // ===============================================================
            // CONTEXT
            // ===============================================================
            if (currentContext != null) ...[
              AppSpacing.gapSm,

              Divider(height: 1, color: colors.outlineVariant),

              AppSpacing.gapSm,

              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      LucideIcons.fileText,
                      color: colors.onSecondaryContainer,
                      size: 16,
                    ),
                  ),

                  AppSpacing.hGapSm,

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current guideline context',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentContext!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Clear context',
                    onPressed: onClearContext,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.x, size: 17),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ERROR
// ===========================================================================

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
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            color: colors.onErrorContainer,
            size: 18,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),

          TextButton(
            onPressed: isRetrying ? null : onRetry,
            child: Text(isRetrying ? 'Retrying...' : 'Retry'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SOURCES
// ===========================================================================

class _SourcesStrip extends StatelessWidget {
  const _SourcesStrip({required this.citations, required this.onCitation});

  final List<RagCitation> citations;
  final ValueChanged<RagCitation> onCitation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            LucideIcons.bookOpenCheck,
            size: 16,
            color: colors.primary,
          ),
        ),
        title: Text(
          '${citations.length} approved '
          'source${citations.length == 1 ? '' : 's'}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Open the evidence used for the latest answer',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        children: [
          for (var index = 0; index < citations.length; index++)
            _CitationTile(
              index: index,
              citation: citations[index],
              onTap: () {
                onCitation(citations[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _CitationTile extends StatelessWidget {
  const _CitationTile({
    required this.index,
    required this.citation,
    required this.onTap,
  });

  final int index;
  final RagCitation citation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final navigable = citation.guidelineId.trim().isNotEmpty;

    return ListTile(
      dense: true,
      enabled: navigable,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.primary,
        child: Text(
          '${index + 1}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        citation.displayLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        navigable
            ? 'Open cited guideline section'
            : 'Source navigation unavailable',
      ),
      trailing: navigable
          ? const Icon(LucideIcons.chevronRight, size: 18)
          : Icon(LucideIcons.lock, size: 16, color: colors.onSurfaceVariant),
      onTap: navigable ? onTap : null,
    );
  }
}
