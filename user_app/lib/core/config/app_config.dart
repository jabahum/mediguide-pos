import 'package:flutter/foundation.dart';
import 'package:user_app/core/config/environment.dart';
import 'package:user_app/core/config/flavor.dart';

final class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.debugToolsEnabled,
  });

  final Flavor flavor;
  final String apiBaseUrl;
  final bool debugToolsEnabled;

  bool get isProduction => flavor == Flavor.production;
  bool get isDevelopment => flavor == Flavor.development;
  bool get isStaging => flavor == Flavor.staging;

  static AppConfig _current = _fromFlavor(Environment.flavor);

  static AppConfig get current => _current;

  static void configure(Flavor flavor, {bool? debugToolsEnabled}) {
    _current = _fromFlavor(flavor, debugToolsEnabled: debugToolsEnabled);
  }

  static AppConfig _fromFlavor(Flavor flavor, {bool? debugToolsEnabled}) =>
      AppConfig(
        flavor: flavor,
        apiBaseUrl: normalizeApiBaseUrlForPlatform(
          Environment.configuredApiBaseUrl.isNotEmpty
              ? Environment.configuredApiBaseUrl
              : Environment.defaultApiBaseUrl(flavor),
          defaultTargetPlatform,
        ),
        debugToolsEnabled:
            flavor != Flavor.production &&
            (debugToolsEnabled ?? Environment.configuredDebugToolsEnabled),
      );
}

String normalizeApiBaseUrlForPlatform(String value, TargetPlatform platform) {
  final trimmed = value.trim().replaceFirst(RegExp(r'/$'), '');
  if (platform != TargetPlatform.android) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || (uri.host != 'localhost' && uri.host != '127.0.0.1')) {
    return trimmed;
  }
  return uri.replace(host: '10.0.2.2').toString();
}
