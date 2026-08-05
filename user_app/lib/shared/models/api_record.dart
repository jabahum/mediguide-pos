/// Framework-neutral record returned by the MediGuide backend API.
class ApiRecord {
  ApiRecord(Map<String, dynamic> value)
    : data = Map<String, dynamic>.from(value);

  final Map<String, dynamic> data;

  String get id => getStringValue('id');
  String get collectionId => getStringValue('collectionId');
  String get collectionName => getStringValue('collectionName');
  String get created => getStringValue('created');
  String get updated => getStringValue('updated');

  bool containsKey(String key) => data.containsKey(key);

  T get<T>(String key, [T? fallback]) {
    final value = data[key];
    if (value is T) {
      return value;
    }

    if (T == String && value != null) {
      return value.toString() as T;
    }
    if (T == int && value is num) {
      return value.toInt() as T;
    }
    if (T == double && value is num) {
      return value.toDouble() as T;
    }
    if (T == bool && value is String) {
      return (value.toLowerCase() == 'true') as T;
    }
    if (value is List && fallback is List<String>) {
      return value.map((item) => item.toString()).toList() as T;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value) as T;
    }
    if (fallback != null || null is T) {
      return fallback as T;
    }

    throw StateError('Record field "$key" is missing or is not a $T');
  }

  String getStringValue(String key, [String fallback = '']) =>
      get<String>(key, fallback);

  bool getBoolValue(String key, [bool fallback = false]) =>
      get<bool>(key, fallback);

  double getDoubleValue(String key, [double fallback = 0]) =>
      get<double>(key, fallback);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}

/// Framework-neutral paginated backend response.
class PagedResult<T> {
  const PagedResult({
    required this.page,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
    required this.items,
  });

  final int page;
  final int perPage;
  final int totalItems;
  final int totalPages;
  final List<T> items;
}

/// Event shape retained while realtime collection endpoints are introduced.
class ApiRecordSubscriptionEvent {
  const ApiRecordSubscriptionEvent({required this.action, this.record});

  final String action;
  final ApiRecord? record;
}
