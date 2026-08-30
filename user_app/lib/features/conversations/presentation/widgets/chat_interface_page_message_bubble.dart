part of '../screens/chat_interface_page.dart';

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
