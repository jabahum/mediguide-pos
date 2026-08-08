import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/home/presentation/controllers/home_controller.dart';

/// Slim messages bar — shows unread count badge inline, tappable to open chat list.
class MessagesCard extends ConsumerWidget {
  const MessagesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;

    final unread = ref.watch(
      homeControllerProvider.select(
        (value) => value.valueOrNull?.unreadMessagesCount ?? 0,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => AppNavigator.push(AppRoutes.chatList),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(LucideIcons.messageCircle, size: 18, color: cs.primary),
              AppSpacing.hGapSm,
              Text(
                'Messages',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (unread > 0) ...[
                AppSpacing.hGapSm,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : unread.toString(),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: cs.onError,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
