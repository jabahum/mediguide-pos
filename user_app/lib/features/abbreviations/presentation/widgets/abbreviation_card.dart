import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
import 'package:user_app/core/constants/app_spacing.dart';

/// Dictionary-style abbreviation list item.
/// Bold abbreviation on the left, meaning on the right, divider below.
class AbbreviationCard extends StatelessWidget {
  final Abbreviation abbreviation;
  final VoidCallback? onTap;

  const AbbreviationCard({super.key, required this.abbreviation, this.onTap});

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
                // Abbreviation — fixed width, bold, primary color
                SizedBox(
                  width: 80,
                  child: Text(
                    abbreviation.displayAbbreviation,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                // Meaning + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        abbreviation.meaning,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (abbreviation.hasDescription) ...[
                        const SizedBox(height: 2),
                        Text(
                          abbreviation.description,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: AppSpacing.md,
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
