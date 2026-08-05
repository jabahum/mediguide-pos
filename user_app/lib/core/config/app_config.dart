import 'package:flutter/foundation.dart';
import 'package:user_app/core/config/environment.dart';
import 'package:user_app/core/config/flavor.dart';

final class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  final Flavor flavor;
  final String apiBaseUrl;

  bool get isProduction => flavor == Flavor.production;

  static final current = AppConfig(
    flavor: Environment.flavor,
    apiBaseUrl: normalizeApiBaseUrlForPlatform(
      Environment.configuredApiBaseUrl.isNotEmpty
          ? Environment.configuredApiBaseUrl
          : Environment.defaultApiBaseUrl(),
      defaultTargetPlatform,
    ),
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
