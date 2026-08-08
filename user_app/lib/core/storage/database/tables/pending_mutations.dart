// lib/core/database/tables/pending_mutations.dart

import 'package:drift/drift.dart';

class PendingMutations extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text().nullable()();

  TextColumn get operation => text()();

  TextColumn get payload => text()();

  TextColumn get scope => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get nextRetryAt => dateTime().nullable()();
}
