import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/storage/local_storage_service.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/shared/widgets/app_logo.dart';

part '../widgets/onboarding_page_brand_header.dart';
part '../widgets/onboarding_page_clinical_illustration.dart';
part '../widgets/onboarding_page_orbit_icon.dart';
part '../widgets/onboarding_page_benefits_card.dart';
part '../widgets/onboarding_page_benefit.dart';
part '../widgets/onboarding_page_benefit_divider.dart';
part '../widgets/onboarding_page_guest_access_notice.dart';

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
    if (!await _markOnboardingComplete(context)) {
      return;
    }

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

    if (!await _markOnboardingComplete(context)) {
      return;
    }

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

  Future<bool> _markOnboardingComplete(BuildContext context) async {
    try {
      await PreferenceUtils.setBool(SharedPreferencesKeys.notFirstTime, true);
      return true;
    } catch (_) {
      if (context.mounted) {
        AppMessage.error(
          context,
          'MediGuide could not save your onboarding choice. Please try again.',
        );
      }
      return false;
    }
  }
}

// ============================================================================
// BRAND HEADER
// ============================================================================
