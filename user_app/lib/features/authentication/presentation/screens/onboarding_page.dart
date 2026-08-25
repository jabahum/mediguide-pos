import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/storage/local_storage_service.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/shared/widgets/app_logo.dart';

/// First-run MediGuide welcome screen.
///
/// Goals:
/// - Explain what MediGuide provides.
/// - Establish trust in reviewed Ministry guidance.
/// - Allow immediate guest access.
/// - Allow authentication while preserving a requested destination.
/// - Avoid sending guests directly into authenticated/private routes.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.primaryContainer.withValues(alpha: 0.35),
                colors.surface,
                colors.surface,
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = Responsive.horizontalPadding(context);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - AppSpacing.lg).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // =================================================
                            // BRAND
                            // =================================================
                            const _BrandHeader(),

                            AppSpacing.gapLg,

                            // =================================================
                            // HERO
                            // =================================================
                            const _ClinicalIllustration(),

                            AppSpacing.gapLg,

                            // =================================================
                            // INTRO
                            // =================================================
                            Text(
                              'Clinical guidance at the point of care',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),

                            AppSpacing.gapSm,

                            Text(
                              'Access reviewed guidelines, medicines, clinical '
                              'tools and public health updates from one place.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),

                            AppSpacing.gapXl,

                            // =================================================
                            // BENEFITS
                            // =================================================
                            const _BenefitsCard(),

                            AppSpacing.gapXl,

                            // =================================================
                            // PRIMARY ACTIONS
                            // =================================================
                            FilledButton.icon(
                              onPressed: () {
                                _continueAsGuest(context);
                              },
                              icon: const Icon(
                                LucideIcons.arrowRight,
                                size: 19,
                              ),
                              label: const Text('Explore as Guest'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                              ),
                            ),

                            AppSpacing.gapSm,

                            OutlinedButton.icon(
                              onPressed: () {
                                _continueToAuthentication(context);
                              },
                              icon: const Icon(LucideIcons.logIn, size: 19),
                              label: const Text('Sign In / Create Account'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                              ),
                            ),

                            AppSpacing.gapMd,

                            // =================================================
                            // GUEST EXPLANATION
                            // =================================================
                            const _GuestAccessNotice(),

                            AppSpacing.gapXl,

                            // =================================================
                            // FOOTER
                            // =================================================
                            Text(
                              'Ministry of Health • Uganda',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'MediGuide supports clinical decision-making '
                              'and does not replace professional judgement.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // GUEST
  // ==========================================================================

  Future<void> _continueAsGuest(BuildContext context) async {
    await _markOnboardingComplete();

    if (!context.mounted) {
      return;
    }

    //
    // Deliberately DO NOT forward `redirect` here.
    //
    // The original destination may be authenticated.
    // Guest users should first enter the public MediGuide experience.
    //
    context.go(AppRoutes.home);
  }

  // ==========================================================================
  // AUTHENTICATION
  // ==========================================================================

  Future<void> _continueToAuthentication(BuildContext context) async {
    final requested = GoRouterState.of(
      context,
    ).uri.queryParameters['redirect']?.trim();

    await _markOnboardingComplete();

    if (!context.mounted) {
      return;
    }

    if (requested == null || requested.isEmpty) {
      context.go(AppRoutes.login);

      return;
    }

    //
    // Preserve the destination through login.
    //
    // Example:
    //
    // /onboarding?redirect=/library
    //
    // becomes:
    //
    // /login?redirect=%2Flibrary
    //
    context.go(
      '${AppRoutes.login}'
      '?redirect=${Uri.encodeQueryComponent(requested)}'
      '&reason=authentication_required',
    );
  }

  Future<void> _markOnboardingComplete() {
    return PreferenceUtils.setBool(SharedPreferencesKeys.notFirstTime, true);
  }
}

// ============================================================================
// BRAND HEADER
// ============================================================================

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      header: true,
      label: 'MediGuide. Official Uganda Clinical Guidelines.',
      child: Column(
        children: [
          const AppLogo(logoSize: 86),

          AppSpacing.gapSm,

          Text(
            'MediGuide',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Uganda Clinical Guidelines',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CLINICAL ILLUSTRATION
// ============================================================================

class _ClinicalIllustration extends StatelessWidget {
  const _ClinicalIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      image: true,
      label:
          'Clinical guidance illustration showing guidelines, safety, health and facilities.',
      child: SizedBox(
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ----------------------------------------------------------------
            // Outer glow
            // ----------------------------------------------------------------
            Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),

            // ----------------------------------------------------------------
            // Main circle
            // ----------------------------------------------------------------
            Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),

            Icon(LucideIcons.stethoscope, size: 72, color: colors.primary),

            const _OrbitIcon(
              alignment: Alignment(-0.92, -0.78),
              icon: LucideIcons.bookOpenText,
            ),

            const _OrbitIcon(
              alignment: Alignment(0.92, -0.78),
              icon: LucideIcons.shieldCheck,
            ),

            const _OrbitIcon(
              alignment: Alignment(-0.92, 0.78),
              icon: LucideIcons.heartPulse,
            ),

            const _OrbitIcon(
              alignment: Alignment(0.92, 0.78),
              icon: LucideIcons.hospital,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ORBIT ICON
// ============================================================================

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({required this.alignment, required this.icon});

  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: colors.primary, size: 21),
      ),
    );
  }
}

// ============================================================================
// BENEFITS
// ============================================================================

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: const Column(
        children: [
          _Benefit(
            icon: LucideIcons.shieldCheck,
            title: 'Trusted guidance',
            description:
                'Reviewed clinical guidance from approved health sources.',
          ),

          _BenefitDivider(),

          _Benefit(
            icon: LucideIcons.cloudDownload,
            title: 'Available offline',
            description:
                'Save supported guidelines for reliable access when connectivity is limited.',
          ),

          _BenefitDivider(),

          _Benefit(
            icon: LucideIcons.bellRing,
            title: 'Stay up to date',
            description:
                'Access newly published guidance, outbreak updates and situation reports.',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BENEFIT
// ============================================================================

class _Benefit extends StatelessWidget {
  const _Benefit({
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
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

// ============================================================================
// DIVIDER
// ============================================================================

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ============================================================================
// GUEST NOTICE
// ============================================================================

class _GuestAccessNotice extends StatelessWidget {
  const _GuestAccessNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Guest access allows public clinical content. Sign in for bookmarks, notes, downloads and synchronization.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.info,
              size: 19,
              color: colors.onSecondaryContainer,
            ),

            AppSpacing.hGapSm,

            Expanded(
              child: Text(
                'Guest access includes public clinical content. '
                'Sign in to sync bookmarks, notes, reading progress '
                'and offline downloads.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
