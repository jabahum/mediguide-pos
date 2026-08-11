import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/shared/models/models.dart' as models;
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/shared/widgets/html_styles.dart';
import 'package:user_app/features/guidelines/presentation/widgets/clinical_callout.dart';

class GuidelineSectionWidget extends StatelessWidget {
  final models.GuidelineSection section;
  final String content;

  const GuidelineSectionWidget({
    super.key,
    required this.section,
    required this.content,
  });

  IconData _getSectionIcon() {
    switch (section) {
      case models.GuidelineSection.definition:
        return LucideIcons.bookOpen;
      case models.GuidelineSection.causes:
        return LucideIcons.search;
      case models.GuidelineSection.clinicalFeatures:
        return LucideIcons.stethoscope;
      case models.GuidelineSection.differentialDiagnosis:
        return LucideIcons.gitBranch;
      case models.GuidelineSection.classification:
        return LucideIcons.layers;
      case models.GuidelineSection.generalManagement:
        return LucideIcons.settings;
      case models.GuidelineSection.medication:
        return LucideIcons.pill;
      case models.GuidelineSection.monitoring:
        return LucideIcons.activity;
      case models.GuidelineSection.prevention:
        return LucideIcons.shield;
      case models.GuidelineSection.specialNotes:
        return LucideIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getSectionIcon(),
              size: 20,
              color: context.theme.colorScheme.primary,
            ),
            AppSpacing.gapSm,
            Expanded(
              child: Text(
                section.label,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        for (final part in parseGuidelineCallouts(content))
          switch (part) {
            GuidelineHtmlPart(:final content) => Html(
              data: content,
              style: HtmlStyles.content(context),
            ),
            GuidelineCalloutPart(:final callout) => ClinicalCalloutCard(
              callout: callout,
            ),
          },
        AppSpacing.elementGap,
      ],
    );
  }
}
