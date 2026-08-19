import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/app.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/config/flavor.dart';
import 'package:user_app/core/debug/network_inspector.dart';
import 'package:user_app/core/storage/local_storage_service.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:user_app/core/services/firebase_service.dart';

/// Initializes platform services and injects the application dependency graph.
Future<void> bootstrap({Flavor? flavor, bool? debugToolsEnabled}) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.configure(
    flavor ?? Flavor.development,
    debugToolsEnabled: debugToolsEnabled,
  );

  final preferences = await PreferenceUtils.init();
  final networkInspector = NetworkInspectorStore();
  final apiClient = await BackendApiService(
    networkInspector: AppConfig.current.debugToolsEnabled
        ? networkInspector
        : null,
  ).init();
  final authService = await AuthService(apiClient).init();
  final aiContextService = await AiContextService().init();
  final firebaseService = await MediGuideFirebaseService(
    apiClient,
    authService,
    preferences,
  ).init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        backendApiServiceProvider.overrideWithValue(apiClient),
        authServiceProvider.overrideWithValue(authService),
        aiContextServiceProvider.overrideWithValue(aiContextService),
        firebaseServiceProvider.overrideWithValue(firebaseService),
        networkInspectorProvider.overrideWithValue(networkInspector),
      ],
      child: const MediGuideApp(),
    ),
  );
}
