import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/theme/app_theme.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:user_app/shared/providers/connectivity_provider.dart';
import 'package:user_app/features/settings/presentation/controllers/language_controller.dart';
import 'package:user_app/l10n/app_translations.dart';

class MediGuideApp extends ConsumerWidget {
  const MediGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    ref.watch(backendReconnectProvider);
    final router = ref.watch(appRouterProvider);
    ref.listen(firebaseOpenedMessageProvider, (_, message) {
      final rawLocation = message.valueOrNull?.data['action_url'];
      if (rawLocation == null || rawLocation.isEmpty) return;
      final location = AppRoutes.safeDestination(rawLocation, fallback: '');
      if (location.isNotEmpty) router.push(location);
    });
    final languageCode =
        ref.watch(languageControllerProvider).valueOrNull?.currentCode ?? 'en';
    AppTranslation.setLocale(Locale(languageCode));
    final themeMode = ref.watch(
      appSettingsControllerProvider.select(
        (settings) => settings.materialThemeMode,
      ),
    );

    return GestureDetector(
      onTap: Common.dismissKeyboard,
      child: ToastificationWrapper(
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: AppTranslation.locale,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: 800, name: TABLET),
              Breakpoint(start: 801, end: 1920, name: DESKTOP),
              Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
        ),
      ),
    );
  }
}
