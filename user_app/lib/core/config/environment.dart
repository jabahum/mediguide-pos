import 'package:flutter/foundation.dart';
import 'package:user_app/core/config/flavor.dart';

abstract final class Environment {
  static const flavorName = String.fromEnvironment(
    'MEDIGUIDE_FLAVOR',
    defaultValue: 'development',
  );
  static const configuredApiBaseUrl = String.fromEnvironment(
    'MEDIGUIDE_API_BASE_URL',
    defaultValue: '',
  );
  static const configuredDebugToolsEnabled = bool.fromEnvironment(
    'MEDIGUIDE_DEBUG_TOOLS_ENABLED',
    defaultValue: false,
  );

  static Flavor get flavor => Flavor.fromEnvironment(flavorName);

  static String defaultApiBaseUrl([Flavor? selectedFlavor]) {
    final activeFlavor = selectedFlavor ?? flavor;
    if (activeFlavor == Flavor.production) {
      return 'https://mediguide.health.go.ug';
    }
    if (activeFlavor == Flavor.staging) {
      return 'https://staging.mediguide.health.go.ug';
    }
    if (kIsWeb) return 'http://127.0.0.1:8080';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8080',
      _ => 'http://127.0.0.1:8080',
    };
  }
}
