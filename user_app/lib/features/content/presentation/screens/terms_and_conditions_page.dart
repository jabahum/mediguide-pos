import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/l10n/app_translations.dart';

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

class _LegalDocumentHeader extends StatelessWidget {
  const _LegalDocumentHeader({required this.lastUpdated});

  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final formattedDate =
        '${lastUpdated.day.toString().padLeft(2, '0')}/'
        '${lastUpdated.month.toString().padLeft(2, '0')}/'
        '${lastUpdated.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.scale, color: colors.primary, size: 23),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.termsAndConditions.tr,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Please review these terms before using MediGuide.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                AppSpacing.gapSm,

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.calendarDays,
                        size: 13,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${AppTranslationKey.lastUpdated.tr}: $formattedDate',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// LEGAL SECTION
// ===========================================================================

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.children,
  });

  final String number;
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: colors.primary, size: 19),
            ),

            AppSpacing.hGapSm,

            Expanded(
              child: Text(
                '$number. $title',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),

        AppSpacing.gapMd,

        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) AppSpacing.gapMd,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// PARAGRAPH
// ===========================================================================

class _LegalParagraph extends StatelessWidget {
  const _LegalParagraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.55,
      ),
    );
  }
}

// ===========================================================================
// SUBHEADING
// ===========================================================================

class _LegalSubheading extends StatelessWidget {
  const _LegalSubheading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ===========================================================================
// BULLET LIST
// ===========================================================================

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  items[index],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          if (index < items.length - 1) AppSpacing.gapSm,
        ],
      ],
    );
  }
}

// ===========================================================================
// CLINICAL / LEGAL NOTICE
// ===========================================================================

class _LegalNotice extends StatelessWidget {
  const _LegalNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.onTertiaryContainer),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CONTACT
// ===========================================================================

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: LucideIcons.landmark,
            label: 'Organization',
            value: 'Ministry of Health Uganda',
          ),

          Divider(height: 1, indent: 56, color: colors.outlineVariant),

          const _ContactRow(
            icon: LucideIcons.mail,
            label: 'Email',
            value: 'support@health.go.ug',
            selectable: true,
          ),

          Divider(height: 1, indent: 56, color: colors.outlineVariant),

          const _ContactRow(
            icon: LucideIcons.globe,
            label: 'Website',
            value: 'www.health.go.ug',
            selectable: true,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),

          AppSpacing.hGapMd,

          SizedBox(
            width: 82,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: selectable
                ? SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// DIVIDER
// ===========================================================================

class _LegalDivider extends StatelessWidget {
  const _LegalDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// ===========================================================================
// FOOTER
// ===========================================================================

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;

    return Column(
      children: [
        Icon(LucideIcons.shieldCheck, size: 22, color: colors.primary),

        AppSpacing.gapSm,

        Text(
          'MediGuide',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 4),

        Text(
          '© $currentYear Ministry of Health Uganda. All rights reserved.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),

        const SizedBox(height: 4),

        Text(
          'Technical implementation and ownership statements should follow the approved MediGuide governance arrangement.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
