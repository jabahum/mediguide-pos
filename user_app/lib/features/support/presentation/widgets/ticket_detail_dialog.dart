import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/support/presentation/controllers/help_center_controller.dart';
import 'package:user_app/features/support/presentation/controllers/help_center_state.dart';
import 'package:user_app/features/support/presentation/widgets/ticket_reply_card.dart';
import 'package:user_app/shared/models/models.dart';

/// Full-screen dialog for viewing ticket details and its conversation.
class TicketDetailDialog extends ConsumerStatefulWidget {
  const TicketDetailDialog({super.key, required this.ticketId});

  final String ticketId;

  static Future<void> show(BuildContext context, String ticketId) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) {
        return TicketDetailDialog(ticketId: ticketId);
      },
    );
  }

  @override
  ConsumerState<TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends ConsumerState<TicketDetailDialog> {
  final _replyFormKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref
          .read(helpCenterControllerProvider.notifier)
          .loadTicketDetails(widget.ticketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(helpCenterControllerProvider);

    final controller = ref.read(helpCenterControllerProvider.notifier);

    final cs = context.theme.colorScheme;

    return PopScope(
      canPop: !state.isAddingReply,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(
            state.selectedTicket?.subject ?? 'Ticket Details',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(LucideIcons.x),
            onPressed: state.isAddingReply
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
          ),
        ),

        // ===================================================
        // BODY
        // ===================================================
        body: _buildBody(
          context: context,
          state: state,
          controller: controller,
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required HelpCenterState state,
    required HelpCenterController controller,
  }) {
    // =====================================================
    // INITIAL LOADING
    // =====================================================

    if (state.isLoading && state.selectedTicket == null) {
      return const AppLoadingView(message: 'Loading ticket details...');
    }

    // =====================================================
    // ERROR
    // =====================================================

    if (state.loadTicketError != null && state.selectedTicket == null) {
      return AppErrorView(
        error: state.loadTicketError!,
        onRetry: () {
          controller.loadTicketDetails(widget.ticketId);
        },
      );
    }

    final ticket = state.selectedTicket;

    // =====================================================
    // MISSING TICKET
    // =====================================================

    if (ticket == null) {
      return EmptyState.noData(
        title: 'Ticket not found',
        description:
            'This support ticket could not be found or is no longer available.',
        actionLabel: 'Close',
        onAction: () {
          Navigator.of(context).pop();
        },
      );
    }

    // =====================================================
    // CONTENT
    // =====================================================

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () {
              return controller.loadTicketDetails(widget.ticketId);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: [
                _TicketHeader(ticket: ticket),

                AppSpacing.gapLg,

                Divider(
                  color: context.theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),

                AppSpacing.gapSm,

                _ConversationHeader(
                  replyCount: state.currentTicketReplies.length,
                ),

                AppSpacing.gapMd,

                _RepliesSection(replies: state.currentTicketReplies),

                AppSpacing.gapLg,
              ],
            ),
          ),
        ),

        // ===================================================
        // REPLY INPUT
        // ===================================================
        if (ticket.status != TicketStatus.closed)
          _ReplyComposer(
            formKey: _replyFormKey,
            isSubmitting: state.isAddingReply,
            onSubmit: () {
              _submitReply(controller);
            },
          ),
      ],
    );
  }

  Future<void> _submitReply(HelpCenterController controller) async {
    if (!(_replyFormKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    final message =
        _replyFormKey.currentState!.value['reply']?.toString().trim() ?? '';

    if (message.isEmpty) {
      return;
    }

    final created = await controller.addReplyToCurrentTicket(message);

    if (!mounted || !created) {
      return;
    }

    _replyFormKey.currentState?.reset();
  }
}

// =========================================================
// TICKET HEADER
// =========================================================

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =================================================
        // STATUS / PRIORITY / TIME
        // =================================================
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ticket.status.color,
              ),
            ),

            const SizedBox(width: 6),

            Text(
              ticket.status.label,
              style: context.textTheme.labelMedium?.copyWith(
                color: ticket.status.color,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (ticket.isHighPriority) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('·', style: TextStyle(color: cs.onSurfaceVariant)),
              ),
              Icon(LucideIcons.flag, size: 14, color: ticket.priority.color),
              const SizedBox(width: 4),
              Text(
                ticket.priority.label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: ticket.priority.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const Spacer(),

            Text(
              ticket.timeAgo,
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),

        AppSpacing.gapSm,

        // =================================================
        // SUBJECT
        // =================================================
        Text(
          ticket.subject,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),

        // =================================================
        // CATEGORY
        // =================================================
        if (ticket.category.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          _CategoryChip(label: ticket.category),
        ],

        AppSpacing.gapMd,

        // =================================================
        // DESCRIPTION
        // =================================================
        Text(
          ticket.description,
          style: context.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// =========================================================
// CATEGORY CHIP
// =========================================================

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.tag, size: 13, color: cs.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// CONVERSATION HEADER
// =========================================================

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.replyCount});

  final int replyCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Row(
      children: [
        Icon(LucideIcons.messagesSquare, size: 16, color: cs.onSurfaceVariant),

        const SizedBox(width: 8),

        Text(
          'CONVERSATION',
          style: context.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),

        const Spacer(),

        if (replyCount > 0)
          Text(
            '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
            style: context.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

// =========================================================
// REPLIES
// =========================================================

class _RepliesSection extends StatelessWidget {
  const _RepliesSection({required this.replies});

  final List<SupportTicketReply> replies;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) {
      return EmptyState.noData(
        title: 'No replies yet',
        description: 'Replies from you or the support team will appear here.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < replies.length; index++) ...[
          TicketReplyCard(reply: replies[index]),
          if (index != replies.length - 1) AppSpacing.sm.gap,
        ],
      ],
    );
  }
}

// =========================================================
// REPLY COMPOSER
// =========================================================

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.formKey,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormBuilderState> formKey;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: FormBuilder(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'reply',
                    enabled: !isSubmitting,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.7,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.minLength(1),
                    ]),
                  ),
                ),

                AppSpacing.hGapSm,

                SizedBox(
                  width: 46,
                  height: 46,
                  child: IconButton.filled(
                    tooltip: 'Send reply',
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(LucideIcons.send),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
