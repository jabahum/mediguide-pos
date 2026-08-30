part of '../screens/chat_interface_page.dart';

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
