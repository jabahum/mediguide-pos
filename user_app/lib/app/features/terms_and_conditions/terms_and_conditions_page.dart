import 'package:flutter/material.dart';
import '../../translations/app_translations.dart';
import '../../utils/app_spacing.dart';
import '../../utils/responsive.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslationKey.termsAndConditions),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: context.responsiveVerticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              AppTranslationKey.termsAndConditions,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              '${AppTranslationKey.lastUpdated}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapLg,

            // Acceptance of Terms Section
            Text(
              AppTranslationKey.acceptanceOfTerms,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              AppTranslationKey.acceptanceOfTermsContent,
              style: theme.textTheme.bodyMedium,
            ),
            AppSpacing.gapLg,

            Divider(color: theme.colorScheme.outlineVariant),
            AppSpacing.gapLg,

            // About MediGuide Section
            Text(
              AppTranslationKey.appDescription,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              AppTranslationKey.appDescriptionContent,
              style: theme.textTheme.bodyMedium,
            ),
            AppSpacing.gapLg,

            Divider(color: theme.colorScheme.outlineVariant),
            AppSpacing.gapLg,

            // User Obligations Section
            Text(
              AppTranslationKey.userObligations,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              AppTranslationKey.userObligationsContent,
              style: theme.textTheme.bodyMedium,
            ),
            AppSpacing.gapSm,
            // Additional user obligations as bullet points
            ...const [
              '• Ensure accurate and up-to-date professional information',
              '• Use the application only for legitimate medical purposes',
              '• Maintain patient confidentiality at all times',
              '• Report any bugs or security vulnerabilities immediately',
              '• Comply with local medical practice regulations and standards',
            ].map(
              (obligation) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(obligation, style: theme.textTheme.bodyMedium),
              ),
            ),
            AppSpacing.gapLg,

            Divider(color: theme.colorScheme.outlineVariant),
            AppSpacing.gapLg,

            // Data Collection and Privacy Section
            Text(
              AppTranslationKey.dataCollection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              AppTranslationKey.dataCollectionContent,
              style: theme.textTheme.bodyMedium,
            ),
            AppSpacing.gapSm,
            Text(
              'We collect the following types of information:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.gapXs,
            ...const [
              '• User account information (name, email, professional credentials)',
              '• Usage analytics to improve app performance and features',
              '• Error logs for debugging and troubleshooting',
              '• App preferences and settings',
              '• Anonymous usage statistics for research purposes',
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(item, style: theme.textTheme.bodyMedium),
              ),
            ),
            AppSpacing.gapLg,

            Divider(color: theme.colorScheme.outlineVariant),
            AppSpacing.gapLg,

            // Contact Information Section
            Text(
              AppTranslationKey.contactInformation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              AppTranslationKey.contactInformationContent,
              style: theme.textTheme.bodyMedium,
            ),
            AppSpacing.gapSm,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MediGuide Development Team',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: support@health.go.ug',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Website: www.health.go.ug',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapLg,

            // Footer
            Center(
              child: Text(
                '© ${DateTime.now().year} By Gother Technologies(U) Ltd. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            AppSpacing.gapLg,
          ],
        ),
      ),
    );
  }
}
