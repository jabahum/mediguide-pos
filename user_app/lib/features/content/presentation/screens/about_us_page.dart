import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/core/utils/responsive.dart';

part '../widgets/about_us_page_about_hero.dart';
part '../widgets/about_us_page_about_section.dart';
part '../widgets/about_us_page_feature_tile.dart';
part '../widgets/about_us_page_action_tile.dart';
part '../widgets/about_us_page_metadata_badge.dart';
part '../widgets/about_us_page_section_divider.dart';
part '../widgets/about_us_page_about_footer.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) {
      return;
    }

    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslationKey.aboutMediGuide.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Clinical guidance platform',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
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
                _AboutHero(version: _version, buildNumber: _buildNumber),

                AppSpacing.gapXl,

                _AboutSection(
                  icon: LucideIcons.target,
                  title: AppTranslationKey.ourMission.tr,
                  description:
                      'Why MediGuide exists and the clinical need it supports.',
                  child: Text(
                    AppTranslationKey.missionDescription.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),

                AppSpacing.gapLg,

                _AboutSection(
                  icon: LucideIcons.layoutGrid,
                  title: 'What MediGuide provides',
                  description:
                      'Core clinical reference and decision-support resources.',
                  child: Column(
                    children: [
                      _FeatureTile(
                        icon: LucideIcons.bookOpenText,
                        title: AppTranslationKey.guidelines.tr,
                        description:
                            AppTranslationKey.accessToClinicGuidelines.tr,
                      ),
                      const _SectionDivider(),
                      _FeatureTile(
                        icon: LucideIcons.pill,
                        title: AppTranslationKey.drugIndex.tr,
                        description: AppTranslationKey
                            .comprehensiveMedicationDatabase
                            .tr,
                      ),
                      const _SectionDivider(),
                      const _FeatureTile(
                        icon: LucideIcons.calculator,
                        title: 'Clinical tools',
                        description:
                            'Calculators, algorithms and decision-support references.',
                      ),
                      const _SectionDivider(),
                      _FeatureTile(
                        icon: LucideIcons.stethoscope,
                        title: AppTranslationKey.consultants.tr,
                        description:
                            AppTranslationKey.medicalExpertsDirectory.tr,
                      ),
                      const _SectionDivider(),
                      _FeatureTile(
                        icon: LucideIcons.hospital,
                        title: AppTranslationKey.healthInfrastructure.tr,
                        description:
                            AppTranslationKey.healthcareFacilitiesList.tr,
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapLg,

                _AboutSection(
                  icon: LucideIcons.lifeBuoy,
                  title: AppTranslationKey.contactSupport.tr,
                  description: 'Get help, report an issue or share feedback.',
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: LucideIcons.mail,
                        title: AppTranslationKey.emailSupport.tr,
                        subtitle: 'support@health.go.ug',
                        trailingIcon: LucideIcons.externalLink,
                        onTap: () {
                          Common.sendEmail('support@health.go.ug');
                        },
                      ),
                      const _SectionDivider(),
                      _ActionTile(
                        icon: LucideIcons.messageSquareText,
                        title: AppTranslationKey.feedback.tr,
                        subtitle: AppTranslationKey.shareYourFeedback.tr,
                        onTap: () {
                          AppNavigator.push(AppRoutes.helpCenter);
                        },
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapLg,

                _AboutSection(
                  icon: LucideIcons.shieldCheck,
                  title: 'Legal & privacy',
                  description:
                      'Review terms, privacy and information-use policies.',
                  child: _ActionTile(
                    icon: LucideIcons.fileText,
                    title: AppTranslationKey.termsAndPrivacy.tr,
                    subtitle: AppTranslationKey.legalInformation.tr,
                    onTap: () {
                      AppNavigator.push(AppRoutes.termsAndConditions);
                    },
                  ),
                ),

                AppSpacing.gapLg,

                const _AboutFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// HERO
// ===========================================================================
