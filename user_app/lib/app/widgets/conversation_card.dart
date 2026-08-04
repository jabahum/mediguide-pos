import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/models/models.dart';
import '../utils/app_spacing.dart';

/// Messenger-style conversation card
class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final User? Function(Conversation) getOtherParticipant;
  final String Function(Conversation) getConversationName;
  final String Function(DateTime) getRelativeTime;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.getOtherParticipant,
    required this.getConversationName,
    required this.getRelativeTime,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = getOtherParticipant(conversation);
    final displayName = getConversationName(conversation);
    final lastActivityTime = conversation.lastActivityDate != null
        ? getRelativeTime(conversation.lastActivityDate!)
        : '';
    final messagePreview = conversation.latestMessageContent;
    final hasMessage = messagePreview.isNotEmpty;

    // Subtitle: message preview or user info fallback
    final subtitle = hasMessage ? messagePreview : _userInfoSubtitle(otherUser);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.colorScheme.secondaryContainer,
              ),
              child: Icon(
                LucideIcons.user,
                size: 24,
                color: context.theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastActivityTime.isNotEmpty)
                        Text(
                          lastActivityTime,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (hasMessage) ...[
                        Icon(
                          LucideIcons.messageCircle,
                          size: 14,
                          color: context.theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          subtitle,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _userInfoSubtitle(User? user) {
    if (user == null) return '';
    if (user.jobTitle.isNotEmpty) return user.jobTitle;
    if (user.organization.isNotEmpty) return user.organization;
    if (user.department.isNotEmpty) return user.department;
    return user.email;
  }
}
