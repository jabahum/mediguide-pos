import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/data/services/auth_service.dart';
import 'package:user_app/app/data/services/openai_service.dart';
import 'package:user_app/app/data/services/ai_context_service.dart';
import 'package:user_app/app/features/auth/auth_controller.dart';
import 'package:user_app/app/features/settings/app_settings_controller.dart';
import 'package:user_app/app/features/settings/connectivity_provider.dart';
import 'package:user_app/app/providers/core_providers.dart';
import 'package:user_app/app/routes/app_pages.dart';
import 'package:user_app/app/themes/app_theme.dart';
import 'package:user_app/app/translations/app_translations.dart';
import 'package:user_app/app/utils/common.dart';

import 'app/utils/preference_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await PreferenceUtils.init();

  // Initialize workmanager for background tasks (available for future use)
  // await Workmanager().initialize(callbackDispatcher);

  // Initialize services
  await _initServices();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MyApp(),
    ),
  );
}

/// Initialize all required services
Future<void> _initServices() async {
  // Initialize core services in order
  await Get.putAsync(() => AuthService().init());

  // Initialize the Go backend compatibility client.
  await Get.putAsync(() => BackendApiService().init());

  // Initialize OpenAI service for AI assistant
  await Get.putAsync(() => OpenAiService().init());

  // Initialize AI Context service for context-aware AI assistance
  await Get.putAsync(() => AiContextService().init());
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start session restoration before protected routes make redirect
    // decisions. GetX remains the temporary router while feature state moves
    // to Riverpod.
    ref.watch(authControllerProvider);
    ref.watch(backendReconnectProvider);
    final themeMode = ref.watch(
      appSettingsControllerProvider.select(
        (settings) => settings.materialThemeMode,
      ),
    );
    return GestureDetector(
      onTap: () => Common.dismissKeyboard(),
      child: ToastificationWrapper(
        child: GetMaterialApp(
          initialRoute: AppRoutes.main,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          getPages: AppPages.pages,
          locale: AppTranslation.locale,
          translationsKeys: AppTranslation.translations,
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
