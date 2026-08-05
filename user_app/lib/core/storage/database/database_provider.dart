import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:user_app/core/storage/database/app_database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
}
