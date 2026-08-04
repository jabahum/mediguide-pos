import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:bubble/bubble.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/utils/app_spacing.dart';

import '../../../app/features/chat_interface/chat_interface_controller.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../utils/loading.dart';
import '../../widgets/user_avatar.dart';

class ChatInterfacePage extends ConsumerStatefulWidget {
  const ChatInterfacePage({super.key, this.otherUser});

  final User? otherUser;

  @override
  ConsumerState<ChatInterfacePage> createState() => _ChatInterfacePageState();
}

class _ChatInterfacePageState extends ConsumerState<ChatInterfacePage> {
  final TextEditingController textController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  bool canSend = false;

  @override
  void initState() {
    super.initState();

    textController.addListener(() {
      final nextCanSend = textController.text.trim().isNotEmpty;

      if (nextCanSend != canSend) {
        setState(() {
          canSend = nextCanSend;
        });
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    inputFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.otherUser;
    if (otherUser == null) {
      return const Scaffold(
        body: Center(child: Text('Conversation unavailable')),
      );
    }
    final provider = chatInterfaceControllerProvider(otherUser);
    final controller = ref.watch(provider);
    ref.listen<int>(provider.select((value) => value.messages.length), (
      previous,
      next,
    ) {
      if (next != previous) _scrollToBottom();
    });
    final cs = context.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        title: _ChatAppBarTitle(otherUser: controller.otherUser),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (controller.isLoading) {
                  return const CenteredLoading.medium();
                }

                if (controller.messages.isEmpty) {
                  return _EmptyChatState(
                    onFocusInput: () => inputFocusNode.requestFocus(),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final previous = index > 0
                        ? controller.messages[index - 1]
                        : null;

                    final showDateSeparator = _shouldShowDateSeparator(
                      previous?.createdDate,
                      message.createdDate,
                    );

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(
                            label: _formatMessageDate(message.createdDate),
                          ),
                        _MessageBubble(
                          message: message,
                          currentUserId: controller.currentUserId,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          _MessageInputBar(
            controller: textController,
            focusNode: inputFocusNode,
            canSend: canSend,
            onSend: () => _sendMessage(controller),
          ),
        ],
      ),
      backgroundColor: cs.surface,
    );
  }

  void _sendMessage(ChatInterfaceController controller) {
    final text = textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    controller.sendTextMessage(text).then((sent) {
      if (sent && mounted) textController.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
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
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today';
    }

    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  final User otherUser;

  const _ChatAppBarTitle({required this.otherUser});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final displayName = otherUser.name.isNotEmpty
        ? otherUser.name
        : otherUser.email;

    final subtitle = otherUser.email;

    return Row(
      children: [
        UserAvatar.small(
          name: otherUser.name.isNotEmpty ? otherUser.name : otherUser.email,
        ),

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
                subtitle,
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

class _EmptyChatState extends StatelessWidget {
  final VoidCallback onFocusInput;

  const _EmptyChatState({required this.onFocusInput});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                LucideIcons.messageCircle,
                size: 36,
                color: cs.primary,
              ),
            ),

            AppSpacing.md.gap,

            Text(
              'Start a conversation',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              'Send a message to get started.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            AppSpacing.lg.gap,

            FilledButton.icon(
              onPressed: onFocusInput,
              icon: const Icon(LucideIcons.send),
              label: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final String label;

  const _DateSeparator({required this.label});

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
  final Message message;
  final String? currentUserId;

  const _MessageBubble({required this.message, required this.currentUserId});

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
    if (dateTime == null) return '';

    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ReplyPreview extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _ReplyPreview({required this.message, required this.isMe});

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
  final Message message;
  final String? currentUserId;
  final Color color;

  const _MessageStatusIcon({
    required this.message,
    required this.currentUserId,
    required this.color,
  });

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
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
  });

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
