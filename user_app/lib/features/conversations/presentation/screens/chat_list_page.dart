import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_list_controller.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/loading.dart';
import 'package:user_app/shared/widgets/conversation_card.dart';
import 'package:user_app/core/widgets/empty_state.dart';
import 'package:user_app/shared/widgets/filter_button.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(chatListControllerProvider);
    final cs = context.theme.colorScheme;

    return Scaffold(
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
            hasActiveFilters: controller.hasActiveFilters,
            onPressed: () => controller.showFilterModal(context),
            onReset: controller.hasActiveFilters
                ? controller.clearAllFilters
                : null,
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(controller.refreshConversations),
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
                  onOpenFilters: () => controller.showFilterModal(context),
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
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, Conversation>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Conversation>(
                      itemBuilder: (context, conversation, index) {
                        return _ConversationCardShell(
                          child: ConversationCard(
                            conversation: conversation,
                            onTap: () =>
                                _openConversation(conversation, controller),
                            getOtherParticipant: controller.getOtherParticipant,
                            getConversationName: controller.getConversationName,
                            getRelativeTime: controller.getRelativeTime,
                          ),
                        );
                      },

                      // =========================
                      // ERROR STATE
                      // =========================
                      firstPageErrorIndicatorBuilder: (context) {
                        return _ConversationErrorState(
                          onRetry: controller.refreshConversations,
                        );
                      },

                      newPageErrorIndicatorBuilder: (context) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: EmptyState(
                            icon: LucideIcons.messageCircle,
                            title: 'Failed to load more',
                            description: 'Please try again',
                            onAction: fetchNextPage,
                          ),
                        );
                      },

                      // =========================
                      // EMPTY STATE
                      // =========================
                      noItemsFoundIndicatorBuilder: (context) {
                        return _EmptyConversationState(
                          isFiltered: controller.hasActiveFilters,
                          onClearFilters: controller.clearAllFilters,
                        );
                      },

                      // =========================
                      // LOADING STATES
                      // =========================
                      firstPageProgressIndicatorBuilder: (context) =>
                          const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xl),
                            child: CenteredLoading.large(),
                          ),

                      newPageProgressIndicatorBuilder: (context) =>
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: CenteredLoading.medium(),
                          ),

                      noMoreItemsIndicatorBuilder: (context) =>
                          const SizedBox(height: AppSpacing.lg),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: cs.surface,
    );
  }

  void _openConversation(
    Conversation conversation,
    ChatListController controller,
  ) {
    final otherUser = controller.getOtherParticipant(conversation);

    if (otherUser != null) {
      AppNavigator.pushNamed(AppRoutes.chatInterface, arguments: otherUser);
    }
  }
}

class _ConversationsHeaderCard extends StatelessWidget {
  final VoidCallback onOpenFilters;

  const _ConversationsHeaderCard({required this.onOpenFilters});

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
  final Widget child;

  const _ConversationCardShell({required this.child});

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

class _EmptyConversationState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onClearFilters;

  const _EmptyConversationState({
    required this.isFiltered,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isFiltered ? LucideIcons.searchX : LucideIcons.messageCircle,
              color: cs.primary,
              size: 36,
            ),
          ),

          AppSpacing.md.gap,

          Text(
            isFiltered
                ? 'No matching conversations'
                : AppTranslationKey.noConversationsFound.tr,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            isFiltered
                ? 'Try adjusting your filters.'
                : AppTranslationKey.startNewConversation.tr,
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          if (isFiltered) ...[
            AppSpacing.lg.gap,
            FilledButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(LucideIcons.x),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConversationErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ConversationErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: EmptyState(
        icon: LucideIcons.messageCircle,
        title: AppTranslationKey.error.tr,
        description: AppTranslationKey.checkInternetAndRetry.tr,
        onAction: onRetry,
      ),
    );
  }
}
