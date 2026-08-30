part of '../screens/chat_interface_page.dart';

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
