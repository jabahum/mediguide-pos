import 'package:user_app/core/config/flavor.dart';

abstract final class Environment {
  static const developmentApiBaseUrl = 'http://localhost:8080';
  static const productionApiBaseUrl = 'https://mediguide.health.go.ug';

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
    return switch (selectedFlavor ?? flavor) {
      Flavor.development => developmentApiBaseUrl,
      Flavor.staging || Flavor.production => productionApiBaseUrl,
    };
  }

  static String apiBaseUrlForFlavor(
    Flavor selectedFlavor, {
    String configured = configuredApiBaseUrl,
  }) {
    final override = configured.trim().replaceFirst(RegExp(r'/$'), '');
    if (selectedFlavor == Flavor.development) {
      // A development build must never silently send test traffic or local
      // credentials to production. LAN and dedicated development endpoints
      // remain available through MEDIGUIDE_API_BASE_URL.
      if (override.isEmpty || _usesProductionHost(override)) {
        return developmentApiBaseUrl;
      }
      return override;
    }
    return override.isEmpty ? defaultApiBaseUrl(selectedFlavor) : override;
  }

  static bool _usesProductionHost(String value) {
    final configuredUri = Uri.tryParse(value);
    final productionUri = Uri.parse(productionApiBaseUrl);
    return configuredUri?.host.toLowerCase() ==
        productionUri.host.toLowerCase();
  }
}
