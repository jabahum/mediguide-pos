import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
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
  void dispose() {
    _textController
      ..removeListener(_handleTextChanged)
      ..dispose();

    _inputFocusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.otherUser;

    if (otherUser == null) {
      return Scaffold(
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

    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        title: _ChatAppBarTitle(otherUser: otherUser),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildConversationBody(
              context: context,
              state: state,
              controller: controller,
            ),
          ),

          _MessageInputBar(
            controller: _textController,
            focusNode: _inputFocusNode,
            canSend: _canSend && !state.isLoading,
            onSend: () {
              _sendMessage(controller);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversationBody({
    required BuildContext context,
    required ChatInterfaceState state,
    required ChatInterfaceController controller,
  }) {
    if (state.isLoading && state.messages.isEmpty) {
      return const AppLoadingView(message: 'Loading conversation...');
    }

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

    if (state.messages.isEmpty) {
      return EmptyState.noData(
        title: 'Start a conversation',
        description: 'Send a message to get started.',
        actionLabel: 'Send Message',
        onAction: () {
          _inputFocusNode.requestFocus();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return controller.loadMessages();
      },
      child: ListView.builder(
        controller: _scrollController,
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

          return Column(
            children: [
              if (showDateSeparator)
                _DateSeparator(label: _formatMessageDate(message.createdDate)),

              _MessageBubble(
                message: message,
                currentUserId: controller.currentUserId,
              ),
            ],
          );
        },
      ),
    );
  }

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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

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

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today';
    }

    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${dateTime.day}/'
        '${dateTime.month}/'
        '${dateTime.year}';
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  const _ChatAppBarTitle({required this.otherUser});

  final User otherUser;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final displayName = otherUser.name.isNotEmpty
        ? otherUser.name
        : otherUser.email;

    return Row(
      children: [
        UserAvatar.small(name: displayName),

        AppSpacing.md.gap,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                otherUser.email,
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
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.currentUserId});

  final Message message;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final isMe = message.sender == currentUserId;

    final bubbleColor = isMe ? cs.primary : cs.surfaceContainerHighest;

    final textColor = isMe ? cs.onPrimary : cs.onSurface;

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Bubble(
          alignment: isMe ? Alignment.topRight : Alignment.topLeft,
          nip: isMe ? BubbleNip.rightTop : BubbleNip.leftTop,
          color: bubbleColor,
          radius: const Radius.circular(18),
          margin: const BubbleEdges.all(0),
          padding: const BubbleEdges.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.replyTo.isNotEmpty) ...[
                  _ReplyPreview(message: message, isMe: isMe),
                  AppSpacing.xs.gap,
                ],

                Text(
                  message.content,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.createdDate),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 5),
                      _MessageStatusIcon(
                        message: message,
                        currentUserId: currentUserId,
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ],
                  ],
                ),
              ],
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

    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.isMe});

  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final replyToMessage = message.replyToMessage;

    if (replyToMessage == null) {
      return const SizedBox.shrink();
    }

    final baseColor = isMe ? cs.onPrimary : cs.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: baseColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyToMessage.senderUser?.name ?? 'User',
            style: context.textTheme.labelMedium?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyToMessage.content,
            style: context.textTheme.bodySmall?.copyWith(
              color: baseColor.withValues(alpha: 0.85),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

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

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
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
                onSubmitted: (_) {
                  if (canSend) {
                    onSend();
                  }
                },
              ),
            ),

            AppSpacing.sm.gap,

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: canSend ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: IconButton(
                onPressed: canSend ? onSend : null,
                icon: Icon(
                  LucideIcons.send,
                  color: canSend ? cs.onPrimary : cs.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
