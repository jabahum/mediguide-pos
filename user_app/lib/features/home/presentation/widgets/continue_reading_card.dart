import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';

/// A card widget for displaying continue reading progress for guidelines
final _guidelineTitleProvider = FutureProvider.autoDispose
    .family<String, String>((ref, id) async {
      final guideline = await ref
          .read(guidelinePublicationRepositoryProvider)
          .content(id);
      return guideline.publication.title;
    });

class ContinueReadingCard extends ConsumerWidget {
  final ReadingProgress progress;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool compact;

  const ContinueReadingCard({
    super.key,
    required this.progress,
    required this.onTap,
    this.onBookmark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(_guidelineTitleProvider(progress.guidelineId));
    if (compact) {
      return _CompactContinueReadingCard(
        progress: progress,
        title: title,
        onTap: onTap,
      );
    }
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

class _CompactContinueReadingCard extends StatelessWidget {
  const _CompactContinueReadingCard({
    required this.progress,
    required this.title,
    required this.onTap,
  });

  final ReadingProgress progress;
  final AsyncValue<String> title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.bookOpenText,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              AppSpacing.md.gap,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.valueOrNull ?? 'Medical guideline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      progress.currentSection.trim().isEmpty
                          ? 'Resume reading'
                          : progress.currentSection.replaceAll('_', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress.progressPercentage.clamp(0, 1),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.sm.gap,
              Text(
                progress.progressText,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(LucideIcons.chevronRight, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}
