import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/core/utils/responsive.dart';

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

class _AboutHero extends StatelessWidget {
  const _AboutHero({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final versionLabel = version.isEmpty
        ? 'Loading version...'
        : buildNumber.isEmpty
        ? 'Version $version'
        : 'Version $version ($buildNumber)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: Responsive.doubleValue(
              context,
              mobile: 76,
              tablet: 84,
              desktop: 92,
            ),
            height: Responsive.doubleValue(
              context,
              mobile: 76,
              tablet: 84,
              desktop: 92,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Image.asset('assets/coat_of_arms.png', fit: BoxFit.contain),
          ),

          AppSpacing.hGapLg,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MediGuide',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Uganda clinical guidance and reference platform',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                AppSpacing.gapSm,

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _MetadataBadge(
                      icon: LucideIcons.package,
                      label: versionLabel,
                    ),
                    const _MetadataBadge(
                      icon: LucideIcons.landmark,
                      label: 'Ministry of Health Uganda',
                    ),
                  ],
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
// SECTION
// ===========================================================================

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.primary, size: 18),
            ),

            AppSpacing.hGapSm,

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        AppSpacing.gapSm,

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: child is Text
                ? const EdgeInsets.all(AppSpacing.md)
                : EdgeInsets.zero,
            child: child,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// FEATURE TILE
// ===========================================================================

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: colors.primary),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
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
// ACTION TILE
// ===========================================================================

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = LucideIcons.chevronRight,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      minTileHeight: 68,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: colors.primary, size: 19),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Icon(trailingIcon, size: 18, color: colors.onSurfaceVariant),
    );
  }
}

// ===========================================================================
// METADATA BADGE
// ===========================================================================

class _MetadataBadge extends StatelessWidget {
  const _MetadataBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSecondaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ===========================================================================
// FOOTER
// ===========================================================================

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(LucideIcons.heartPulse, size: 22, color: colors.primary),

        AppSpacing.gapSm,

        Text(
          'MediGuide',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 3),

        Text(
          'Supporting access to trusted clinical guidance.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
