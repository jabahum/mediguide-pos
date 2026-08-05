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

  static Flavor get flavor => Flavor.fromEnvironment(flavorName);

  static String defaultApiBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8080';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8080',
      _ => 'http://127.0.0.1:8080',
    };
  }
}
