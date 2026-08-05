import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh reference data is served without another request', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cache = TtlResponseCache(preferences: preferences);
    var loads = 0;

    final first = await cache.getOrLoad(
      key: 'languages',
      ttl: const Duration(minutes: 10),
      load: () async {
        loads++;
        return {
          'items': ['English'],
        };
      },
    );
    final second = await cache.getOrLoad(
      key: 'languages',
      ttl: const Duration(minutes: 10),
      load: () async {
        loads++;
        return {
          'items': ['French'],
        };
      },
    );

    expect(first, second);
    expect(loads, 1);
  });

  test('expired reference data remains available when refresh fails', () async {
    const key = 'facility-levels';
    final encodedKey = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    SharedPreferences.setMockInitialValues({
      'mediguide.reference-cache.v1.$encodedKey': jsonEncode({
        'cached_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        'data': {
          'items': ['Hospital'],
        },
      }),
    });
    final cache = TtlResponseCache(
      preferences: await SharedPreferences.getInstance(),
    );

    final value = await cache.getOrLoad(
      key: key,
      ttl: const Duration(minutes: 10),
      load: () async => throw Exception('offline'),
    );

    expect(value['items'], ['Hospital']);
  });
}
