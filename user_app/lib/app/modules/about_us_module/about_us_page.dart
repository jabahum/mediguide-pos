import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../translations/app_translations.dart';
import '../../utils/app_spacing.dart';
import '../../utils/responsive.dart';
import '../../routes/app_pages.dart';
import 'about_us_controller.dart';

class AboutUsPage extends GetWidget<AboutUsController> {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTranslationKey.aboutUs.tr,
          style: TextStyle(
            fontSize: Responsive.fontSize(
              context,
              mobile: 20.0,
              tablet: 22.0,
              desktop: 24.0,
            ),
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: context.isMobile ? 0 : 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: context.responsiveVerticalPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AboutHeroCard(version: '1.0.0'),

                AppSpacing.lg.gap,

                _InfoSectionCard(
                  icon: LucideIcons.target,
                  title: AppTranslationKey.ourMission.tr,
                  child: Text(
                    AppTranslationKey.missionDescription.tr,
                    style: context.textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),

                AppSpacing.lg.gap,

                _InfoSectionCard(
                  icon: LucideIcons.sparkles,
                  title: AppTranslationKey.keyFeatures.tr,
                  child: Column(
                    children: [
                      _FeatureCard(
                        icon: LucideIcons.bookOpen,
                        title: AppTranslationKey.guidelines.tr,
                        description:
                            AppTranslationKey.accessToClinicGuidelines.tr,
                      ),
                      AppSpacing.sm.gap,
                      _FeatureCard(
                        icon: LucideIcons.pillBottle,
                        title: AppTranslationKey.drugIndex.tr,
                        description: AppTranslationKey
                            .comprehensiveMedicationDatabase
                            .tr,
                      ),
                      AppSpacing.sm.gap,
                      _FeatureCard(
                        icon: LucideIcons.stethoscope,
                        title: AppTranslationKey.consultants.tr,
                        description:
                            AppTranslationKey.medicalExpertsDirectory.tr,
                      ),
                      AppSpacing.sm.gap,
                      _FeatureCard(
                        icon: LucideIcons.building2,
                        title: AppTranslationKey.healthInfrastructure.tr,
                        description:
                            AppTranslationKey.healthcareFacilitiesList.tr,
                      ),
                    ],
                  ),
                ),

                AppSpacing.lg.gap,

                _InfoSectionCard(
                  icon: LucideIcons.headphones,
                  title: AppTranslationKey.contactSupport.tr,
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: LucideIcons.mail,
                        title: AppTranslationKey.emailSupport.tr,
                        subtitle: 'support@health.go.ug',
                        trailingIcon: LucideIcons.externalLink,
                        onTap: () =>
                            controller.launchEmail('support@health.go.ug'),
                      ),
                      _SectionDivider(),
                      _ActionTile(
                        icon: LucideIcons.messageSquare,
                        title: AppTranslationKey.feedback.tr,
                        subtitle: AppTranslationKey.shareYourFeedback.tr,
                        onTap: () => Get.toNamed(AppRoutes.helpCenter),
                      ),
                    ],
                  ),
                ),

                AppSpacing.lg.gap,

                _InfoSectionCard(
                  icon: LucideIcons.scale,
                  title: AppTranslationKey.legalInformation.tr,
                  child: _ActionTile(
                    icon: LucideIcons.fileText,
                    title: AppTranslationKey.termsAndPrivacy.tr,
                    subtitle: AppTranslationKey.legalInformation.tr,
                    onTap: () => Get.toNamed(AppRoutes.termsAndConditions),
                  ),
                ),

                AppSpacing.sectionGap,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutHeroCard extends StatelessWidget {
  final String version;

  const _AboutHeroCard({required this.version});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: Responsive.doubleValue(
              context,
              mobile: 108.0,
              tablet: 124.0,
              desktop: 136.0,
            ),
            height: Responsive.doubleValue(
              context,
              mobile: 108.0,
              tablet: 124.0,
              desktop: 136.0,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),

          AppSpacing.lg.gap,

          Text(
            AppTranslationKey.aboutMediGuide.tr,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            '${AppTranslationKey.appVersion.tr} $version',
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Made with love by MoH Uganda',
              style: context.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          AppSpacing.md.gap,
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: cs.primary, size: 22),
        ),
        AppSpacing.md.gap,
        Expanded(
          child: Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21, color: cs.primary),
          ),
          AppSpacing.md.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailingIcon;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = LucideIcons.chevronRight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
      title: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Icon(trailingIcon, color: cs.onSurfaceVariant),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Divider(
      height: 1,
      indent: 56,
      color: cs.outlineVariant.withValues(alpha: 0.35),
    );
  }
}
