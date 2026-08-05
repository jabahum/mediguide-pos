import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/constants/app_constants.dart';

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
}
