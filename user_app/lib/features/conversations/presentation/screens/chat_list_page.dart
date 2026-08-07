import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/conversations/presentation/controllers/chat_list_controller.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/conversation_card.dart';
import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatListControllerProvider);

    final controller = ref.read(chatListControllerProvider.notifier);

    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.conversations.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          FilterButton(
            hasActiveFilters: state.hasActiveFilters,
            onPressed: () {
              controller.showFilterModal(context);
            },
            onReset: state.hasActiveFilters ? controller.clearAllFilters : null,
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshConversations();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _ConversationsHeaderCard(
                  onOpenFilters: () {
                    controller.showFilterModal(context);
                  },
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, Conversation>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, Conversation>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Conversation>(
                      itemBuilder: (context, conversation, index) {
                        return _ConversationCardShell(
                          child: ConversationCard(
                            conversation: conversation,
                            onTap: () {
                              _openConversation(conversation, controller);
                            },
                            getOtherParticipant: controller.getOtherParticipant,
                            getConversationName: controller.getConversationName,
                            getRelativeTime: controller.getRelativeTime,
                          ),
                        );
                      },

                      // =========================
                      // FIRST PAGE LOADING
                      // =========================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading conversations...',
                        );
                      },

                      // =========================
                      // NEXT PAGE LOADING
                      // =========================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // =========================
                      // FIRST PAGE ERROR
                      // =========================
                      firstPageErrorIndicatorBuilder: (_) {
                        return AppErrorView(
                          error:
                              pagingState.error ??
                              'Unable to load conversations',
                          title: AppTranslationKey.error.tr,
                          message: AppTranslationKey.checkInternetAndRetry.tr,
                          onRetry: fetchNextPage,
                        );
                      },

                      // =========================
                      // NEXT PAGE ERROR
                      // =========================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'Failed to load more conversations',
                          icon: LucideIcons.messageCircle,
                        );
                      },

                      // =========================
                      // EMPTY
                      // =========================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No matching conversations',
                            description: 'Try adjusting your filters.',
                            actionLabel: 'Clear Filters',
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: AppTranslationKey.noConversationsFound.tr,
                          description:
                              AppTranslationKey.startNewConversation.tr,
                        );
                      },

                      // =========================
                      // END
                      // =========================
                      noMoreItemsIndicatorBuilder: (_) {
                        return PaginationIndicators.noMoreItems();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(
    Conversation conversation,
    ChatListController controller,
  ) {
    final otherUser = controller.getOtherParticipant(conversation);

    if (otherUser == null) {
      return;
    }

    AppNavigator.push(AppRoutes.chat(conversation.id), extra: otherUser);
  }
}

class _ConversationsHeaderCard extends StatelessWidget {
  const _ConversationsHeaderCard({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              LucideIcons.messagesSquare,
              color: cs.primary,
              size: 28,
            ),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.conversations.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'View your conversations and continue consultations.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.sm.gap,

          IconButton.filledTonal(
            onPressed: onOpenFilters,
            icon: const Icon(LucideIcons.slidersHorizontal),
            tooltip: 'Filter conversations',
          ),
        ],
      ),
    );
  }
}

class _ConversationCardShell extends StatelessWidget {
  const _ConversationCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
