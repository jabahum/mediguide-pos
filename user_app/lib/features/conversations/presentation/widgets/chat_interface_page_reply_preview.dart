part of '../screens/chat_interface_page.dart';

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
