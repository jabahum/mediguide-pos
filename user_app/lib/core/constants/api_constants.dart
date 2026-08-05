import 'package:user_app/core/config/app_config.dart';

export 'package:user_app/core/config/app_config.dart'
    show normalizeApiBaseUrlForPlatform;

final String mediguideApiBaseUrl = AppConfig.current.apiBaseUrl;

abstract final class ApiConstants {
  static const healthPath = '/api/healthz';
  static const apiVersion = '/api/v2';
}
