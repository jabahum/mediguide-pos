// lib/core/database/tables/cached_entities.dart

import 'package:drift/drift.dart';

class CachedEntities extends Table {
  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  /// JSON representation of the domain object.
  TextColumn get payload => text()();

  /// Text prepared for offline search.
  TextColumn get searchableText => text().withDefault(const Constant(''))();

  /// Optional metadata used for filtering.
  TextColumn get metadata => text().nullable()();

  /// public:
  ///     shared reference data such as guidelines
  ///
  /// user:<id>:
  ///     user-specific data such as bookmarks/progress
  TextColumn get scope => text().withDefault(const Constant('public'))();

  /// Server-side version when available.
  TextColumn get version => text().nullable()();

  DateTimeColumn get remoteUpdatedAt => dateTime().nullable()();

  DateTimeColumn get cachedAt => dateTime()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId, scope};
}
