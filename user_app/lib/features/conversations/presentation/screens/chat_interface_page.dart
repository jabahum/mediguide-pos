import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/conversations/data/models/message.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_interface_controller.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_interface_state.dart';

import 'package:user_app/shared/widgets/user_avatar.dart';

class ChatInterfacePage extends ConsumerStatefulWidget {
  const ChatInterfacePage({super.key, this.otherUser});

  final User? otherUser;

  @override
  ConsumerState<ChatInterfacePage> createState() => _ChatInterfacePageState();
}

class _ChatInterfacePageState extends ConsumerState<ChatInterfacePage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _canSend = false;

  @override
  void initState() {
    super.initState();

    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_handleTextChanged)
      ..dispose();

    _inputFocusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _handleTextChanged() {
    final next = _textController.text.trim().isNotEmpty;

    if (next == _canSend) {
      return;
    }

    setState(() {
      _canSend = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.otherUser;

    if (otherUser == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState.noData(
          title: 'Conversation unavailable',
          description: 'The person for this conversation could not be found.',
        ),
      );
    }

    final provider = chatInterfaceControllerProvider(otherUser);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

    ref.listen<int>(provider.select((value) => value.messages.length), (
      previous,
      next,
    ) {
      if (previous != next) {
        _scrollToBottom();
      }
    });

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        title: _ChatAppBarTitle(otherUser: otherUser),
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // =================================================================
            // CONTENT
            // =================================================================
            Expanded(
              child: _buildConversationBody(
                context: context,
                state: state,
                controller: controller,
              ),
            ),

            // =================================================================
            // NON-BLOCKING ERROR
            // =================================================================
            if (state.errorMessage != null && state.messages.isNotEmpty)
              _ConversationErrorBanner(
                message: state.errorMessage!,
                onRetry: () {
                  controller.loadMessages();
                },
              ),

            // =================================================================
            // INPUT
            // =================================================================
            _MessageInputBar(
              controller: _textController,
              focusNode: _inputFocusNode,
              canSend: _canSend && !state.isLoading,
              isSending: state.isLoading,
              onSend: () {
                _sendMessage(controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationBody({
    required BuildContext context,
    required ChatInterfaceState state,
    required ChatInterfaceController controller,
  }) {
    // =======================================================================
    // INITIAL LOADING
    // =======================================================================

    if (state.isLoading && state.messages.isEmpty) {
      return const AppLoadingView(message: 'Loading conversation...');
    }

    // =======================================================================
    // INITIAL ERROR
    // =======================================================================

    if (state.errorMessage != null && state.messages.isEmpty) {
      return AppErrorView(
        error: state.errorMessage!,
        title: 'Unable to load conversation',
        message: 'The conversation could not be loaded.',
        onRetry: () {
          controller.findOrCreateConversation();
        },
      );
    }

    // =======================================================================
    // EMPTY
    // =======================================================================

    if (state.messages.isEmpty) {
      return EmptyState.noData(
        title: 'Start a conversation',
        description: 'Send a message to get started.',
        actionLabel: 'Write a message',
        onAction: () {
          _inputFocusNode.requestFocus();
        },
      );
    }

    // =======================================================================
    // MESSAGES
    // =======================================================================

    return RefreshIndicator(
      onRefresh: controller.loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];

          final previous = index > 0 ? state.messages[index - 1] : null;

          final showDateSeparator = _shouldShowDateSeparator(
            previous?.createdDate,
            message.createdDate,
          );

          final showSenderSpacing =
              previous != null && previous.sender != message.sender;

          return Column(
            children: [
              if (showDateSeparator)
                _DateSeparator(label: _formatMessageDate(message.createdDate)),

              if (showSenderSpacing) const SizedBox(height: AppSpacing.xs),

              _MessageBubble(
                message: message,
                currentUserId: controller.currentUserId,
                onCopy: () {
                  _copyMessage(context, message);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // SEND
  // =========================================================================

  Future<void> _sendMessage(ChatInterfaceController controller) async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final sent = await controller.sendTextMessage(text);

    if (!mounted || !sent) {
      return;
    }

    _textController.clear();

    _scrollToBottom();
  }

  // =========================================================================
  // MESSAGE ACTIONS
  // =========================================================================

  Future<void> _copyMessage(BuildContext context, Message message) async {
    final text = message.content.trim();

    if (text.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // =========================================================================
  // SCROLL
  // =========================================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // =========================================================================
  // DATE
  // =========================================================================

  bool _shouldShowDateSeparator(DateTime? previous, DateTime? current) {
    if (current == null) {
      return false;
    }

    if (previous == null) {
      return true;
    }

    return previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
  }

  String _formatMessageDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final localDate = dateTime.toLocal();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final date = DateTime(localDate.year, localDate.month, localDate.day);

    if (date == today) {
      return 'Today';
    }

    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }
}

// ===========================================================================
// APP BAR TITLE
// ===========================================================================

class _ChatAppBarTitle extends StatelessWidget {
  const _ChatAppBarTitle({required this.otherUser});

  final User otherUser;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final displayName = otherUser.name.trim().isNotEmpty
        ? otherUser.name.trim()
        : otherUser.email.trim();

    final subtitle = <String>[
      if (otherUser.jobTitle.trim().isNotEmpty) otherUser.jobTitle.trim(),
      if (otherUser.organization.trim().isNotEmpty)
        otherUser.organization.trim(),
    ].join(' · ');

    return Row(
      children: [
        UserAvatar.small(name: displayName),

        AppSpacing.hGapMd,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle.isNotEmpty ? subtitle : otherUser.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// DATE SEPARATOR
// ===========================================================================

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.outlineVariant)),

          AppSpacing.hGapSm,

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(child: Divider(color: colors.outlineVariant)),
        ],
      ),
    );
  }
}

// ===========================================================================
// MESSAGE BUBBLE
// ===========================================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.currentUserId,
    required this.onCopy,
  });

  final Message message;
  final String? currentUserId;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isMe = message.sender == currentUserId;

    final bubbleColor = isMe ? colors.primary : colors.surfaceContainerHigh;

    final textColor = isMe ? colors.onPrimary : colors.onSurface;

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onCopy,
          child: Bubble(
            alignment: isMe ? Alignment.topRight : Alignment.topLeft,
            nip: isMe ? BubbleNip.rightBottom : BubbleNip.leftBottom,
            nipWidth: 8,
            nipHeight: 7,
            color: bubbleColor,
            radius: const Radius.circular(18),
            margin: const BubbleEdges.all(0),
            padding: const BubbleEdges.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.76,
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =========================================================
                  // REPLY
                  // =========================================================
                  if (message.replyTo.isNotEmpty) ...[
                    _ReplyPreview(message: message, isMe: isMe),
                    AppSpacing.gapXs,
                  ],

                  // =========================================================
                  // CONTENT
                  // =========================================================
                  SelectableText(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // =========================================================
                  // METADATA
                  // =========================================================
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdDate),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (isMe) ...[
                        const SizedBox(width: 5),

                        _MessageStatusIcon(
                          message: message,
                          currentUserId: currentUserId,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final local = dateTime.toLocal();

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }
}

// ===========================================================================
// REPLY PREVIEW
// ===========================================================================

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.isMe});

  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final reply = message.replyToMessage;

    if (reply == null) {
      return const SizedBox.shrink();
    }

    final foreground = isMe ? colors.onPrimary : colors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: foreground, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderUser?.name.trim().isNotEmpty == true
                ? reply.senderUser!.name.trim()
                : 'Message',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            reply.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// MESSAGE STATUS
// ===========================================================================

class _MessageStatusIcon extends StatelessWidget {
  const _MessageStatusIcon({
    required this.message,
    required this.currentUserId,
    required this.color,
  });

  final Message message;
  final String? currentUserId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null || message.sender != currentUserId) {
      return const SizedBox.shrink();
    }

    if (message.readBy.isNotEmpty) {
      return Icon(LucideIcons.checkCheck, size: 15, color: color);
    }

    return Icon(LucideIcons.check, size: 15, color: color);
  }
}

// ===========================================================================
// INPUT BAR
// ===========================================================================

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // =============================================================
              // TEXT INPUT
              // =============================================================
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: colors.primary, width: 1.4),
                    ),
                  ),
                ),
              ),

              AppSpacing.hGapSm,

              // =============================================================
              // SEND
              // =============================================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: canSend ? colors.primary : colors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? Padding(
                        padding: const EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : IconButton(
                        tooltip: 'Send message',
                        onPressed: canSend ? onSend : null,
                        icon: Icon(
                          LucideIcons.send,
                          size: 19,
                          color: canSend
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// NON-BLOCKING ERROR
// ===========================================================================

class _ConversationErrorBanner extends StatelessWidget {
  const _ConversationErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
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
            size: 17,
            color: colors.onErrorContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),

          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
