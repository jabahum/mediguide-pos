import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/constants/storage_keys.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';
import 'package:user_app/core/storage/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy access token migrates from preferences to secure storage',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesKeys.userToken: 'legacy-access-token',
      });
      FlutterSecureStorage.setMockInitialValues({});

      final api = await BackendApiService().init();
      final preferences = await SharedPreferences.getInstance();

      expect(api.accessToken, 'legacy-access-token');
      expect(
        await const FlutterSecureStorage().read(
          key: SharedPreferencesKeys.userToken,
        ),
        'legacy-access-token',
      );
      expect(preferences.containsKey(SharedPreferencesKeys.userToken), isFalse);
    },
  );

  test('production cache adapter persists responses in Drift', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final cache = TtlResponseCache(database: database);
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
          'items': ['Swahili'],
        };
      },
    );

    expect(first, second);
    expect(loads, 1);
    expect(await database.cacheEntry('languages'), isNotNull);
  });
}
