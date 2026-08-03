import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../data/models/models.dart';
import '../../../providers/core_providers.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';

/// A card widget for displaying continue reading progress for guidelines
final _guidelineTitleProvider = FutureProvider.autoDispose
    .family<String, String>((ref, id) async {
      final record = await ref
          .read(guidelineContentRepositoryProvider)
          .guideline(id);
      return Guideline.fromRecord(record).conditionName;
    });

class ContinueReadingCard extends ConsumerWidget {
  final ReadingProgress progress;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;

  const ContinueReadingCard({
    super.key,
    required this.progress,
    required this.onTap,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(_guidelineTitleProvider(progress.guidelineId));
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator at top
              LinearProgressIndicator(
                value: progress.progressPercentage,
                backgroundColor: context.theme.colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.theme.colorScheme.primary,
                ),
              ),

              // Card content
              Expanded(
                child: Padding(
                  padding: context.responsiveCardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with category and bookmark
                      Row(
                        children: [
                          // Category indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.stethoscope,
                                  size: 12,
                                  color: context
                                      .theme
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                AppSpacing.xs.gap,
                                Text(
                                  'Guideline',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: context
                                        .theme
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Bookmark button
                          if (onBookmark != null)
                            IconButton(
                              onPressed: onBookmark,
                              icon: Icon(
                                progress.isBookmarked
                                    ? LucideIcons.bookmark
                                    : LucideIcons.bookmarkPlus,
                                size: 18,
                                color: progress.isBookmarked
                                    ? context.theme.colorScheme.primary
                                    : context
                                          .theme
                                          .colorScheme
                                          .onSurfaceVariant,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(4),
                            ),
                        ],
                      ),

                      AppSpacing.sm.gap,

                      // Guideline title
                      title.isLoading
                          ? Container(
                              height: 16,
                              width: 200,
                              decoration: BoxDecoration(
                                color:
                                    context.theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : Text(
                              title.valueOrNull ?? 'Medical Guideline',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                      AppSpacing.sm.gap,

                      // Current section and progress
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: context.theme.colorScheme.primary,
                          ),
                          AppSpacing.xs.gap,
                          Expanded(
                            child: Text(
                              'Section: ${progress.currentSection}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color:
                                    context.theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      AppSpacing.xs.gap,

                      // Progress text
                      Row(
                        children: [
                          Text(
                            progress.progressText,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            progress.status.label,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Footer with time and continue button
                      Row(
                        children: [
                          // Last read time
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: context.theme.colorScheme.outline,
                              ),
                              AppSpacing.xs.gap,
                              Text(
                                progress.lastReadFormatted,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: context.theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Continue reading button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  progress.progressPercentage > 0
                                      ? 'Continue'
                                      : 'Start',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: context.theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.arrowRight,
                                  size: 12,
                                  color: context.theme.colorScheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
