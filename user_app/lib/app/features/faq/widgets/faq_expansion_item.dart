import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../data/models/models.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';

/// Clean accordion FAQ item — no card, just question row that expands to show the answer.
class FaqExpansionItem extends StatefulWidget {
  final FAQ faq;

  const FaqExpansionItem({super.key, required this.faq});

  @override
  State<FaqExpansionItem> createState() => _FaqExpansionItemState();
}

class _FaqExpansionItemState extends State<FaqExpansionItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      children: [
        // Question row
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured dot
                if (widget.faq.isFeatured)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: _expanded ? FontWeight.w600 : FontWeight.w500,
                      color: _expanded ? cs.primary : cs.onSurface,
                    ),
                  ),
                ),
                AppSpacing.hGapSm,
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Answer (collapsible)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(
              left: widget.faq.isFeatured ? AppSpacing.md + 16 : AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Html(
                  data: widget.faq.answer,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(
                        Responsive.fontSize(
                          context,
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                      ),
                      lineHeight: const LineHeight(1.5),
                      color: cs.onSurfaceVariant,
                    ),
                    "p": Style(margin: Margins.only(bottom: AppSpacing.sm)),
                    "ul, ol": Style(
                      margin: Margins.only(
                        left: AppSpacing.md,
                        bottom: AppSpacing.sm,
                      ),
                    ),
                    "li": Style(margin: Margins.only(bottom: AppSpacing.xs)),
                    "h1, h2, h3, h4, h5, h6": Style(
                      fontWeight: FontWeight.w600,
                      margin: Margins.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                      ),
                    ),
                    "strong, b": Style(fontWeight: FontWeight.w600),
                    "a": Style(
                      color: cs.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                    "blockquote": Style(
                      border: Border(
                        left: BorderSide(color: cs.primary, width: 3),
                      ),
                      padding: HtmlPaddings.only(left: AppSpacing.md),
                      margin: Margins.only(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                      ),
                      backgroundColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  },
                ),
                // Metadata tags
                if (_shouldShowMetadata()) ...[
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      if (widget.faq.isFeatured)
                        _tag(
                          context,
                          AppTranslationKey.featured.tr,
                          cs.primary,
                        ),
                      if (widget.faq.priority != 'normal')
                        _tag(
                          context,
                          FaqPriority.fromString(widget.faq.priority).label,
                          _priorityColor(context),
                        ),
                      if (widget.faq.targetAudience != 'all')
                        _tag(
                          context,
                          FaqTargetAudience.fromString(
                            widget.faq.targetAudience,
                          ).label,
                          cs.secondary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        // Divider
        Divider(
          height: 1,
          indent: AppSpacing.md,
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  bool _shouldShowMetadata() =>
      widget.faq.isFeatured ||
      widget.faq.priority != 'normal' ||
      widget.faq.targetAudience != 'all';

  Widget _tag(BuildContext context, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _priorityColor(BuildContext context) {
    final cs = context.theme.colorScheme;
    return switch (widget.faq.priority.toLowerCase()) {
      'high' || 'critical' => cs.error,
      'low' => cs.onSurfaceVariant,
      _ => cs.secondary,
    };
  }
}
