import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';

part '../widgets/guest_more_page_guest_account_card.dart';
part '../widgets/guest_more_page_account_benefit.dart';
part '../widgets/guest_more_page_more_section.dart';
part '../widgets/guest_more_page_more_item.dart';
part '../widgets/guest_more_page_guest_access_info.dart';

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
                icon: LucideIcons.activity,
                title: 'Diseases & Conditions',
                subtitle: 'Browse approved guidance by disease',
                onTap: () => context.push(AppRoutes.diseases),
              ),
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
