import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/features/support/data/models/support_ticket_reply.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/shared/widgets/user_avatar.dart';

/// Card widget for displaying a support ticket reply in the conversation
class TicketReplyCard extends ConsumerWidget {
  final SupportTicketReply reply;

  const TicketReplyCard({super.key, required this.reply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull?.user;
    final isFromCurrentUser =
        currentUser != null && reply.isFromUser(currentUser.id);
    final isFromSupport = reply.isFromSupport;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar (left side for support, right side for user)
        if (!isFromCurrentUser) ...[
          UserAvatar.small(
            name: reply.authorName,
            avatarUrl:
                null, // TODO: Add avatar support for support ticket replies
            backgroundColor: isFromSupport
                ? context.theme.colorScheme.primary
                : context.theme.colorScheme.secondary,
            textColor: isFromSupport
                ? context.theme.colorScheme.onPrimary
                : context.theme.colorScheme.onSecondary,
          ),
          AppSpacing.gapSm,
        ],

        // Message content
        Expanded(
          child: Column(
            crossAxisAlignment: isFromCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Author and timestamp
              Row(
                mainAxisAlignment: isFromCurrentUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isFromCurrentUser) ...[
                    Text(
                      reply.authorName,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isFromSupport
                            ? context.theme.colorScheme.primary
                            : context.theme.colorScheme.secondary,
                      ),
                    ),
                    AppSpacing.gapXs,
                  ],
                  Text(
                    reply.timeAgo,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isFromCurrentUser) ...[
                    AppSpacing.gapXs,
                    Text(
                      'You',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),

              AppSpacing.gapXs,

              // Message bubble
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: isFromCurrentUser
                      ? context.theme.colorScheme.primary
                      : isFromSupport
                      ? context.theme.colorScheme.secondaryContainer
                      : context.theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12).copyWith(
                    // Remove corner radius for the side the bubble points to
                    bottomLeft: isFromCurrentUser
                        ? const Radius.circular(12)
                        : const Radius.circular(4),
                    bottomRight: isFromCurrentUser
                        ? const Radius.circular(4)
                        : const Radius.circular(12),
                  ),
                ),
                child: Text(
                  reply.message,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isFromCurrentUser
                        ? context.theme.colorScheme.onPrimary
                        : isFromSupport
                        ? context.theme.colorScheme.onSecondaryContainer
                        : context.theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Avatar and spacer for current user (right aligned)
        if (isFromCurrentUser) ...[
          AppSpacing.gapSm,
          UserAvatar.small(
            name: reply.authorName,
            avatarUrl: currentUser.avatar,
          ),
        ],
      ],
    );
  }
}
