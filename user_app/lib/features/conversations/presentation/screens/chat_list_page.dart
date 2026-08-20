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

    final colors = Theme.of(context).colorScheme;

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
              AppTranslationKey.conversations.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Messages and consultations',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          FilterButton(
            hasActiveFilters: state.hasActiveFilters,
            onPressed: () {
              controller.showFilterModal(context);
            },
            onReset: state.hasActiveFilters ? controller.clearAllFilters : null,
          ),
          AppSpacing.hGapXs,
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshConversations();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // CONTEXT
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConversationBrowseCard(
                      hasActiveFilters: state.hasActiveFilters,
                      onOpenFilters: () {
                        controller.showFilterModal(context);
                      },
                    ),

                    if (state.hasActiveFilters) ...[
                      AppSpacing.gapMd,

                      _ActiveConversationFiltersBanner(
                        onEdit: () {
                          controller.showFilterModal(context);
                        },
                        onClear: controller.clearAllFilters,
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      state.hasActiveFilters
                          ? 'Matching conversations'
                          : 'Recent conversations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      state.hasActiveFilters
                          ? 'Showing conversations matching your current filters.'
                          : 'Continue previous conversations and consultations.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    AppSpacing.gapSm,
                  ],
                ),
              ),
            ),

            // =================================================================
            // CONVERSATION LIST
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, Conversation>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, Conversation>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Conversation>(
                      // =====================================================
                      // ITEM
                      // =====================================================
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

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading conversations...',
                        );
                      },

                      // =====================================================
                      // NEXT PAGE LOADING
                      // =====================================================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // =====================================================
                      // FIRST PAGE ERROR
                      // =====================================================
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

                      // =====================================================
                      // NEXT PAGE ERROR
                      // =====================================================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'Failed to load more conversations',
                          icon: LucideIcons.messagesSquare,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No matching conversations',
                            description: 'Try adjusting your filters.',
                            actionLabel: 'Clear filters',
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: AppTranslationKey.noConversationsFound.tr,
                          description:
                              AppTranslationKey.startNewConversation.tr,
                        );
                      },

                      // =====================================================
                      // END
                      // =====================================================
                      noMoreItemsIndicatorBuilder: (_) {
                        return Padding(
                          padding: AppSpacing.vPaddingMd,
                          child: PaginationIndicators.noMoreItems(),
                        );
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

// ===========================================================================
// BROWSE CARD
// ===========================================================================

class _ConversationBrowseCard extends StatelessWidget {
  const _ConversationBrowseCard({
    required this.hasActiveFilters,
    required this.onOpenFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenFilters,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.messagesSquare,
                  color: colors.primary,
                  size: 21,
                ),
              ),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find a conversation',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasActiveFilters
                          ? 'Filters are applied. Tap to adjust them.'
                          : 'Filter conversations by the available participants, status or other fields.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.hGapSm,

              Icon(
                LucideIcons.slidersHorizontal,
                color: colors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ACTIVE FILTERS
// ===========================================================================

class _ActiveConversationFiltersBanner extends StatelessWidget {
  const _ActiveConversationFiltersBanner({
    required this.onEdit,
    required this.onClear,
  });

  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.listFilter,
            size: 18,
            color: colors.onSecondaryContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              'Conversation filters applied',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          TextButton(onPressed: onEdit, child: const Text('Edit')),

          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

// ===========================================================================
// CARD SHELL
// ===========================================================================

class _ConversationCardShell extends StatelessWidget {
  const _ConversationCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
