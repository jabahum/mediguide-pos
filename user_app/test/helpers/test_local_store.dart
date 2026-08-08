import 'package:drift/native.dart';
import 'package:user_app/core/storage/database/app_database.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

final class TestLocalStore {
  TestLocalStore()
    : database = AppDatabase.forTesting(NativeDatabase.memory()) {
    cache = LocalCacheService(database);
  }

  final AppDatabase database;
  late final LocalCacheService cache;

  Future<void> close() => database.close();
}
