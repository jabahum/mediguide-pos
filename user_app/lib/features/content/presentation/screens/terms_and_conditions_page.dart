import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/l10n/app_translations.dart';

part '../widgets/terms_and_conditions_page_widgets.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  /// This should represent the actual date the terms were approved/published.
  ///
  /// Do NOT use DateTime.now() here, otherwise the application will claim
  /// that the legal document was updated every day.
  static final DateTime _lastUpdated = DateTime(2026, 8, 20);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslationKey.termsAndConditions.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Legal, privacy and acceptable-use information',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.responsiveHorizontalPadding,
          AppSpacing.md,
          context.responsiveHorizontalPadding,
          AppSpacing.xxxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===========================================================
                // DOCUMENT INTRO
                // ===========================================================
                _LegalDocumentHeader(lastUpdated: _lastUpdated),

                AppSpacing.gapXl,

                // ===========================================================
                // ACCEPTANCE
                // ===========================================================
                _LegalSection(
                  number: '1',
                  icon: LucideIcons.fileCheck2,
                  title: AppTranslationKey.acceptanceOfTerms.tr,
                  children: [
                    _LegalParagraph(
                      text: AppTranslationKey.acceptanceOfTermsContent.tr,
                    ),
                    const _LegalParagraph(
                      text:
                          'By accessing or using MediGuide, you acknowledge that '
                          'you have read and understood these terms and agree to '
                          'use the platform in accordance with applicable laws, '
                          'professional standards and Ministry of Health policies.',
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // ABOUT MEDIGUIDE
                // ===========================================================
                _LegalSection(
                  number: '2',
                  icon: LucideIcons.info,
                  title: AppTranslationKey.appDescription.tr,
                  children: [
                    _LegalParagraph(
                      text: AppTranslationKey.appDescriptionContent.tr,
                    ),
                    const _LegalParagraph(
                      text:
                          'MediGuide provides access to clinical guidelines, '
                          'medicine references, clinical tools, health-facility '
                          'information and other approved health information.',
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // CLINICAL USE
                // ===========================================================
                const _LegalSection(
                  number: '3',
                  icon: LucideIcons.stethoscope,
                  title: 'Clinical use and professional judgement',
                  children: [
                    _LegalParagraph(
                      text:
                          'MediGuide is a clinical reference and information '
                          'platform. It does not replace professional judgement, '
                          'clinical assessment, local protocols, emergency '
                          'procedures or consultation with an appropriately '
                          'qualified healthcare professional.',
                    ),
                    _LegalNotice(
                      icon: LucideIcons.triangleAlert,
                      text:
                          'Clinical information should be checked against the '
                          'latest approved guideline and the patient’s actual '
                          'clinical circumstances before being acted upon.',
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // USER OBLIGATIONS
                // ===========================================================
                _LegalSection(
                  number: '4',
                  icon: LucideIcons.userCheck,
                  title: AppTranslationKey.userObligations.tr,
                  children: [
                    _LegalParagraph(
                      text: AppTranslationKey.userObligationsContent.tr,
                    ),
                    const _BulletList(
                      items: [
                        'Maintain accurate and current account and professional information.',
                        'Use MediGuide only for legitimate health, clinical, educational or administrative purposes.',
                        'Protect account credentials and do not allow unauthorized persons to use your account.',
                        'Maintain patient confidentiality and comply with applicable privacy requirements.',
                        'Do not enter unnecessary patient-identifiable information into AI or support features.',
                        'Report suspected security vulnerabilities, misuse or significant content errors.',
                        'Comply with applicable health-professional regulations, institutional policies and clinical standards.',
                      ],
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // PRIVACY
                // ===========================================================
                _LegalSection(
                  number: '5',
                  icon: LucideIcons.shieldCheck,
                  title: AppTranslationKey.dataCollection.tr,
                  children: [
                    _LegalParagraph(
                      text: AppTranslationKey.dataCollectionContent.tr,
                    ),
                    const _LegalSubheading(
                      text: 'Information that may be processed',
                    ),
                    const _BulletList(
                      items: [
                        'Account information such as name, email address and professional profile.',
                        'Organization, facility, role or other professional-context information where applicable.',
                        'Application preferences and settings.',
                        'Reading progress, bookmarks, notes and offline-content metadata for signed-in users.',
                        'Usage and performance information needed to improve reliability and usability.',
                        'Diagnostic and error information used for troubleshooting and security monitoring.',
                      ],
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // AI
                // ===========================================================
                const _LegalSection(
                  number: '6',
                  icon: LucideIcons.sparkles,
                  title: 'AI-assisted features',
                  children: [
                    _LegalParagraph(
                      text:
                          'MediGuide may provide AI-assisted navigation or '
                          'question-answering features using approved clinical '
                          'content. AI-generated responses may be incomplete, '
                          'incorrect or unsuitable for a particular patient.',
                    ),
                    _BulletList(
                      items: [
                        'Do not treat an AI response as an independent diagnosis or prescription.',
                        'Review supporting citations and source guidelines before clinical use.',
                        'Do not submit unnecessary patient-identifiable or confidential information.',
                        'Escalate uncertain, high-risk or emergency clinical decisions through normal clinical pathways.',
                      ],
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // OFFLINE CONTENT
                // ===========================================================
                const _LegalSection(
                  number: '7',
                  icon: LucideIcons.cloudDownload,
                  title: 'Offline content',
                  children: [
                    _LegalParagraph(
                      text:
                          'MediGuide may allow selected content to be stored on '
                          'your device for offline access. Offline copies may '
                          'become outdated when newer guidance is published.',
                    ),
                    _LegalParagraph(
                      text:
                          'Users should reconnect periodically so that available '
                          'updates can be identified and downloaded.',
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // AVAILABILITY
                // ===========================================================
                const _LegalSection(
                  number: '8',
                  icon: LucideIcons.server,
                  title: 'Availability and changes',
                  children: [
                    _LegalParagraph(
                      text:
                          'MediGuide services, content and features may be '
                          'updated, suspended or withdrawn where required for '
                          'maintenance, security, regulatory, clinical-content '
                          'or operational reasons.',
                    ),
                    _LegalParagraph(
                      text:
                          'Reasonable efforts are made to maintain service '
                          'availability, but uninterrupted access cannot be guaranteed.',
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // INTELLECTUAL PROPERTY
                // ===========================================================
                const _LegalSection(
                  number: '9',
                  icon: LucideIcons.copyright,
                  title: 'Content and intellectual property',
                  children: [
                    _LegalParagraph(
                      text:
                          'Clinical guidelines, publications, trademarks, '
                          'software, graphics and other material available '
                          'through MediGuide remain subject to the ownership, '
                          'licensing and reuse conditions of their respective '
                          'rights holders.',
                    ),
                    _LegalParagraph(
                      text:
                          'Access through MediGuide does not automatically grant '
                          'permission to redistribute, commercially reuse or alter '
                          'third-party content.',
                    ),
                  ],
                ),

                const _LegalDivider(),

                // ===========================================================
                // CONTACT
                // ===========================================================
                _LegalSection(
                  number: '10',
                  icon: LucideIcons.mail,
                  title: AppTranslationKey.contactInformation.tr,
                  children: [
                    _LegalParagraph(
                      text: AppTranslationKey.contactInformationContent.tr,
                    ),
                    const _ContactCard(),
                  ],
                ),

                AppSpacing.gapXl,

                // ===========================================================
                // FOOTER
                // ===========================================================
                const _LegalFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// DOCUMENT HEADER
// ===========================================================================
