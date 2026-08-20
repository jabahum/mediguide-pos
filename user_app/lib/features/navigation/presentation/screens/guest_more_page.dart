import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';

class GuestMorePage extends StatelessWidget {
  const GuestMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Text(
          'More',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          AppSpacing.sm,
          Responsive.horizontalPadding(context),
          AppSpacing.xxxl,
        ),
        children: [
          // =========================================================
          // GUEST / ACCOUNT
          // =========================================================
          _GuestAccountCard(
            onSignIn: () => context.push(AppRoutes.login),
            onRegister: () => context.push(AppRoutes.register),
          ),

          AppSpacing.gapLg,

          // =========================================================
          // DIRECTORIES
          // =========================================================
          _MoreSection(
            title: 'Directories',
            children: [
              _MoreItem(
                icon: LucideIcons.hospital,
                title: 'Health Facilities',
                subtitle: 'Find health facilities and available services',
                onTap: () => context.push(AppRoutes.healthFacilities),
              ),
              _MoreItem(
                icon: LucideIcons.landmark,
                title: 'Ministry Directory',
                subtitle: 'Official Ministry contacts and departments',
                onTap: () => context.push(AppRoutes.ministryDirectory),
              ),
            ],
          ),

          AppSpacing.gapLg,

          // =========================================================
          // HELP & SUPPORT
          // =========================================================
          _MoreSection(
            title: 'Help & Support',
            children: [
              _MoreItem(
                icon: LucideIcons.circleHelp,
                title: 'Help Center',
                subtitle: 'Get help using MediGuide',
                onTap: () => context.push(AppRoutes.helpCenter),
              ),
              _MoreItem(
                icon: LucideIcons.messageCircleQuestion,
                title: 'Frequently Asked Questions',
                subtitle: 'Answers to common questions',
                onTap: () => context.push(AppRoutes.faq),
              ),
            ],
          ),

          AppSpacing.gapLg,

          // =========================================================
          // ABOUT
          // =========================================================
          _MoreSection(
            title: 'About',
            children: [
              _MoreItem(
                icon: LucideIcons.info,
                title: 'About MediGuide',
                subtitle: 'Learn about the MediGuide platform',
                onTap: () => context.push(AppRoutes.aboutUs),
              ),
              _MoreItem(
                icon: LucideIcons.shieldCheck,
                title: 'Terms & Privacy',
                subtitle: 'Privacy, data handling and legal information',
                onTap: () => context.push(AppRoutes.termsAndConditions),
              ),
            ],
          ),

          AppSpacing.gapLg,

          // =========================================================
          // GUEST INFORMATION
          // =========================================================
          const _GuestAccessInfo(),

          AppSpacing.gapXl,
        ],
      ),
    );
  }
}

// ============================================================================
// GUEST ACCOUNT CARD
// ============================================================================

class _GuestAccountCard extends StatelessWidget {
  const _GuestAccountCard({required this.onSignIn, required this.onRegister});

  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------
          // ICON + TITLE
          // ---------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(LucideIcons.userRound, color: cs.primary, size: 24),
              ),

              AppSpacing.gapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get more from MediGuide',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to personalize your clinical reference experience.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.gapLg,

          // ---------------------------------------------------------
          // BENEFITS
          // ---------------------------------------------------------
          const _AccountBenefit(
            icon: LucideIcons.bookmark,
            text: 'Save bookmarks and notes',
          ),
          const SizedBox(height: 10),

          const _AccountBenefit(
            icon: LucideIcons.history,
            text: 'Sync your reading progress',
          ),
          const SizedBox(height: 10),

          const _AccountBenefit(
            icon: LucideIcons.cloudDownload,
            text: 'Manage downloaded content',
          ),
          const SizedBox(height: 10),

          const _AccountBenefit(
            icon: LucideIcons.bell,
            text: 'Receive important updates',
          ),

          AppSpacing.gapLg,

          // ---------------------------------------------------------
          // ACTIONS
          // ---------------------------------------------------------
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(LucideIcons.logIn, size: 18),
              label: const Text('Sign in'),
            ),
          ),

          AppSpacing.gapSm,

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRegister,
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACCOUNT BENEFIT
// ============================================================================

class _AccountBenefit extends StatelessWidget {
  const _AccountBenefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 17, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION
// ============================================================================

class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],

                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MORE ITEM
// ============================================================================

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ListTile(
        onTap: onTap,
        minTileHeight: 68,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),

        // -----------------------------------------------------------
        // ICON
        // -----------------------------------------------------------
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: cs.primary, size: 19),
        ),

        // -----------------------------------------------------------
        // CONTENT
        // -----------------------------------------------------------
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),

        trailing: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ============================================================================
// GUEST ACCESS INFORMATION
// ============================================================================

class _GuestAccessInfo extends StatelessWidget {
  const _GuestAccessInfo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.bookOpenCheck, color: cs.primary, size: 18),
          ),

          AppSpacing.gapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public clinical guidance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can browse published guidelines, medicines, '
                  'clinical tools and public directories without signing in.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
