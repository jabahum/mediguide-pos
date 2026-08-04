import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/models/ministry_directory.dart';
import '../utils/app_spacing.dart';
import '../utils/common.dart';
import 'ministry_directory_detail_bottom_sheet.dart';

/// Clean contact-list tile for ministry directory entries.
class MinistryDirectoryCard extends StatelessWidget {
  final MinistryDirectory entry;
  final int index;

  const MinistryDirectoryCard({
    super.key,
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: () => MinistryDirectoryDetailBottomSheet.show(context, entry),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Avatar with initials + emergency indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        entry.name.isNotEmpty
                            ? entry.name[0].toUpperCase()
                            : '?',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    if (entry.isEmergencyContact)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: cs.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 2),
                          ),
                          child: const Icon(
                            LucideIcons.shield,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.hGapMd,
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.ministry.label,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.phone.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          entry.phone,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Quick call button
                IconButton(
                  onPressed: () =>
                      Common.makeCall(entry.phone, contactName: entry.name),
                  icon: Icon(LucideIcons.phone, size: 18, color: cs.primary),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Call ${entry.name}',
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: AppSpacing.md + 44 + AppSpacing.md,
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
