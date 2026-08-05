import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:universal_image/universal_image.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/storage/local_storage_service.dart';
import 'package:user_app/core/utils/responsive.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final primaryColor = theme.colorScheme.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FlexColorScheme.themedSystemNavigationBar(context, noAppBar: true),
      child: Scaffold(
        body: SafeArea(
          child: IntroductionScreen(
            key: _introKey,
            pages: [
              PageViewModel(
                title: AppTranslationKey.welcomeToMediGuide,
                body: AppTranslationKey.welcomeBody,
                image: _buildUgandaCoatOfArms(),
                decoration: _pageDecoration(theme, context),
              ),
              PageViewModel(
                title: AppTranslationKey.clinicalGuidelines,
                body: AppTranslationKey.clinicalGuidelinesBody,
                image: _buildIcon(
                  LucideIcons.bookOpen,
                  theme.colorScheme.secondary,
                ),
                decoration: _pageDecoration(theme, context),
              ),
              PageViewModel(
                title: AppTranslationKey.worksOffline,
                body: AppTranslationKey.worksOfflineBody,
                image: _buildIcon(
                  LucideIcons.download,
                  theme.colorScheme.tertiary,
                ),
                decoration: _pageDecoration(theme, context),
              ),
              PageViewModel(
                title: AppTranslationKey.decisionSupportTools,
                body: AppTranslationKey.decisionSupportToolsBody,
                image: _buildIcon(LucideIcons.calculator, primaryColor),
                decoration: _pageDecoration(theme, context),
              ),
              PageViewModel(
                title: AppTranslationKey.readyToTransformCare,
                body: AppTranslationKey.readyToTransformCareBody,
                image: _buildIcon(
                  LucideIcons.check,
                  theme.colorScheme.secondary,
                ),
                decoration: _pageDecoration(theme, context),
              ),
            ],
            onDone: _completeOnboarding,
            onSkip: _completeOnboarding,
            showSkipButton: true,
            showBackButton: true,
            back: Icon(LucideIcons.chevronLeft, color: primaryColor),
            skip: Text(
              AppTranslationKey.skip,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            next: Icon(LucideIcons.chevronRight, color: primaryColor),
            done: Text(
              AppTranslationKey.getStarted,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            dotsDecorator: DotsDecorator(
              size: const Size.square(10.0),
              activeSize: const Size(22.0, 10.0),
              color: theme.colorScheme.outline,
              activeColor: primaryColor,
              spacing: const EdgeInsets.symmetric(horizontal: 3.0),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    await PreferenceUtils.setBool(SharedPreferencesKeys.notFirstTime, true);
    AppNavigator.go(AppRoutes.login);
  }

  Widget _buildUgandaCoatOfArms() {
    return Builder(
      builder: (context) {
        final size = Responsive.doubleValue(
          context,
          mobile: 120.0,
          tablet: 140.0,
          desktop: 160.0,
        );
        return UniversalImage(
          'assets/Coat_of_arms_of_Uganda.svg.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      },
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Builder(
      builder: (context) {
        final padding = Responsive.doubleValue(
          context,
          mobile: 24.0,
          tablet: 32.0,
          desktop: 40.0,
        );
        final iconSize = Responsive.doubleValue(
          context,
          mobile: 80.0,
          tablet: 96.0,
          desktop: 112.0,
        );
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: iconSize, color: color),
        );
      },
    );
  }

  PageDecoration _pageDecoration(ThemeData theme, BuildContext context) {
    final titleFontSize = Responsive.fontSize(
      context,
      mobile: 28.0,
      tablet: 32.0,
      desktop: 36.0,
    );
    final bodyFontSize = Responsive.fontSize(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
    final imagePadding = Responsive.doubleValue(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );
    final horizontalPadding = context.responsiveHorizontalPadding;
    final verticalPadding = context.responsiveVerticalPadding;

    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: titleFontSize,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      bodyTextStyle: TextStyle(
        fontSize: bodyFontSize,
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
      imagePadding: EdgeInsets.all(imagePadding),
      pageColor: theme.colorScheme.surface,
      bodyPadding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0.0,
        horizontalPadding,
        verticalPadding,
      ),
      titlePadding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0.0,
        horizontalPadding,
        verticalPadding,
      ),
      imageFlex: context.isMobile ? 3 : 2,
      bodyFlex: context.isMobile ? 2 : 3,
    );
  }
}
