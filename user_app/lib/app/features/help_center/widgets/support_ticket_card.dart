import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../data/models/models.dart';
import '../../../utils/app_spacing.dart';
import 'ticket_detail_dialog.dart';

/// Clean list-style ticket item — status dot, subject, metadata, chevron.
class SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const SupportTicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return InkWell(
      onTap: () => TicketDetailDialog.show(context, ticket.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator dot
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ticket.status.color,
                ),
              ),
            ),
            AppSpacing.hGapMd,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.subject,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: ticket.isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        ticket.timeAgo,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Description preview
                  Text(
                    ticket.description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Status + priority + category
                  Row(
                    children: [
                      Text(
                        ticket.status.label,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: ticket.status.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (ticket.isHighPriority) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                        Icon(
                          LucideIcons.flag,
                          size: 12,
                          color: ticket.priority.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ticket.priority.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: ticket.priority.color,
                          ),
                        ),
                      ],
                      if (ticket.category.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                        Text(
                          ticket.category,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
