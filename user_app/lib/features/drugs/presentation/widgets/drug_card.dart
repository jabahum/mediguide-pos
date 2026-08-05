import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/constants/app_spacing.dart';

/// Clean list tile for drug index — pill icon, name, brand, key badges, chevron.
class DrugCard extends StatelessWidget {
  final Drug drug;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;

  const DrugCard({
    super.key,
    required this.drug,
    this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.pill, size: 22, color: cs.primary),
                ),
                AppSpacing.hGapMd,
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drug.name,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (drug.brandNames.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          drug.brandNames,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      // Inline metadata with icons
                      Row(
                        children: [
                          if (drug.categories.isNotEmpty) ...[
                            Icon(
                              LucideIcons.tag,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                drug.categories.first.name,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (drug.routeOfAdministration.isNotEmpty) ...[
                            if (drug.categories.isNotEmpty) _dot(cs),
                            Icon(
                              LucideIcons.syringe,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              drug.routeOfAdministration.first.displayName,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (drug.whoEmlStatus) ...[
                            _dot(cs),
                            Icon(
                              LucideIcons.badgeCheck,
                              size: 12,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'WHO',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: cs.onSurfaceVariant,
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

  Widget _dot(ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '·',
      style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
    ),
  );
}
