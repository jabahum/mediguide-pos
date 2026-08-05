import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
import 'package:user_app/core/constants/app_spacing.dart';

class AbbreviationDetailModal extends StatelessWidget {
  final Abbreviation abbreviation;
  final ScrollController? scrollController;

  const AbbreviationDetailModal({
    super.key,
    required this.abbreviation,
    this.scrollController,
  });

  static Future<void> show(BuildContext context, Abbreviation abbreviation) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.56,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return AbbreviationDetailModal(
              abbreviation: abbreviation,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  bool get _hasCategory => abbreviation.hasCategory;

  bool get _hasTags => abbreviation.tags.isNotEmpty;

  bool get _hasMeta => _hasCategory || _hasTags;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          12,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          const _DragHandle(),

          AppSpacing.gapMd,

          _Header(abbreviation: abbreviation),

          AppSpacing.gapLg,

          Text(
            abbreviation.meaning,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),

          if (abbreviation.hasDescription) ...[
            AppSpacing.gapMd,
            Text(
              abbreviation.description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],

          if (_hasMeta) ...[
            AppSpacing.gapLg,
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
            AppSpacing.gapMd,
            _MetaTags(abbreviation: abbreviation),
          ],
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Abbreviation abbreviation;

  const _Header({required this.abbreviation});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          abbreviation.displayAbbreviation,
          style: context.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.primary,
            letterSpacing: 0.8,
          ),
        ),
        if (abbreviation.isCommon) ...[
          const SizedBox(height: 6),
          _InlineBadge(
            icon: LucideIcons.star,
            label: 'commonlyUsedAbbreviation'.tr,
            color: cs.primary,
          ),
        ],
      ],
    );
  }
}

class _MetaTags extends StatelessWidget {
  final Abbreviation abbreviation;

  const _MetaTags({required this.abbreviation});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (abbreviation.hasCategory)
          _InlineBadge(
            icon: LucideIcons.folder,
            label: abbreviation.category!.displayName,
            color: cs.primary,
          ),
        ...abbreviation.tags.map(
          (tag) => _InlineBadge(
            icon: LucideIcons.tag,
            label: tag.displayName,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InlineBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InlineBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
