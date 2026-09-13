import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/config/environment.dart';
import 'package:user_app/core/config/flavor.dart';

void main() {
  test('maps Android localhost API URL to emulator host', () {
    expect(
      normalizeApiBaseUrlForPlatform(
        'http://localhost:8080/',
        TargetPlatform.android,
      ),
      'http://10.0.2.2:8080',
    );
  });

  test('does not change LAN or non-Android URLs', () {
    expect(
      normalizeApiBaseUrlForPlatform(
        'http://192.168.1.10:8080',
        TargetPlatform.android,
      ),
      'http://192.168.1.10:8080',
    );
    expect(
      normalizeApiBaseUrlForPlatform(
        'http://localhost:8080',
        TargetPlatform.iOS,
      ),
      'http://localhost:8080',
    );
  });

  test(
    'development defaults to local API and cannot silently use production',
    () {
      expect(
        Environment.defaultApiBaseUrl(Flavor.development),
        'http://localhost:8080',
      );
      expect(
        Environment.apiBaseUrlForFlavor(
          Flavor.development,
          configured: 'https://mediguide.health.go.ug/api/',
        ),
        'http://localhost:8080',
      );
      expect(
        Environment.apiBaseUrlForFlavor(
          Flavor.development,
          configured: 'http://192.168.1.20:8080/',
        ),
        'http://192.168.1.20:8080',
      );
    },
  );

  test('staging and production retain hosted API defaults', () {
    expect(
      Environment.defaultApiBaseUrl(Flavor.staging),
      Environment.productionApiBaseUrl,
    );
    expect(
      Environment.defaultApiBaseUrl(Flavor.production),
      Environment.productionApiBaseUrl,
    );
  });
}
