import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/shared/widgets/html_styles.dart';

class GenericPageSectionWidget extends StatelessWidget {
  final GenericPageSection section;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const GenericPageSectionWidget({
    super.key,
    required this.section,
    this.showIcon = true,
    this.padding,
  });

  bool get _hasTitle => section.title.trim().isNotEmpty;

  bool get _hasContent => section.content.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasTitle) ...[
            _SectionHeader(title: section.title.trim(), showIcon: showIcon),
            AppSpacing.md.gap,
          ],
          Html(data: section.content, style: HtmlStyles.content(context)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showIcon;

  const _SectionHeader({required this.title, required this.showIcon});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.fileText, size: 20, color: cs.primary),
          ),
          AppSpacing.sm.gap,
        ],
        Expanded(
          child: Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
