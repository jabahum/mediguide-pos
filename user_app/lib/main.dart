import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/data/services/auth_service.dart';
import 'package:user_app/app/data/services/openai_service.dart';
import 'package:user_app/app/data/services/ai_context_service.dart';
import 'package:user_app/app/features/auth/auth_controller.dart';
import 'package:user_app/app/features/settings/app_settings_controller.dart';
import 'package:user_app/app/features/settings/connectivity_provider.dart';
import 'package:user_app/app/features/settings/language_controller.dart';
import 'package:user_app/app/core/di/core_providers.dart';
import 'package:user_app/app/core/navigation/app_router.dart';
import 'package:user_app/app/themes/app_theme.dart';
import 'package:user_app/app/translations/app_translations.dart';
import 'package:user_app/app/utils/common.dart';

import 'app/utils/preference_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await PreferenceUtils.init();

  // Initialize workmanager for background tasks (available for future use)
  // await Workmanager().initialize(callbackDispatcher);

  final services = await _initServices();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        backendApiServiceProvider.overrideWithValue(services.backend),
        authServiceProvider.overrideWithValue(services.auth),
        openAiServiceProvider.overrideWithValue(services.openAi),
        aiContextServiceProvider.overrideWithValue(services.aiContext),
      ],
      child: const MyApp(),
    ),
  );
}

/// Initialize all required services
Future<_AppServices> _initServices() async {
  final backend = await BackendApiService().init();
  final auth = await AuthService(backend).init();
  final openAi = await OpenAiService(backend, auth).init();
  final aiContext = await AiContextService().init();
  return _AppServices(backend, auth, openAi, aiContext);
}

final class _AppServices {
  const _AppServices(this.backend, this.auth, this.openAi, this.aiContext);

  final BackendApiService backend;
  final AuthService auth;
  final OpenAiService openAi;
  final AiContextService aiContext;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    ref.watch(backendReconnectProvider);
    final router = ref.watch(appRouterProvider);
    final languageCode =
        ref.watch(languageControllerProvider).valueOrNull?.currentCode ?? 'en';
    AppTranslation.setLocale(Locale(languageCode));
    final themeMode = ref.watch(
      appSettingsControllerProvider.select(
        (settings) => settings.materialThemeMode,
      ),
    );
    return GestureDetector(
      onTap: () => Common.dismissKeyboard(),
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
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
        ),
      ),
    );
  }
}
