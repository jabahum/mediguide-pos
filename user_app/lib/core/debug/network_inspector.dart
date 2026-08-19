import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum NetworkLogStatus { pending, success, failure }

@immutable
final class NetworkLogEntry {
  const NetworkLogEntry({
    required this.id,
    required this.method,
    required this.uri,
    required this.startedAt,
    required this.requestHeaders,
    required this.requestBody,
    this.status = NetworkLogStatus.pending,
    this.statusCode,
    this.duration,
    this.responseHeaders = const {},
    this.responseBody,
    this.error,
  });

  final String id;
  final String method;
  final Uri uri;
  final DateTime startedAt;
  final Map<String, dynamic> requestHeaders;
  final String? requestBody;
  final NetworkLogStatus status;
  final int? statusCode;
  final Duration? duration;
  final Map<String, dynamic> responseHeaders;
  final String? responseBody;
  final String? error;

  NetworkLogEntry complete({
    required NetworkLogStatus status,
    int? statusCode,
    Duration? duration,
    Map<String, dynamic>? responseHeaders,
    String? responseBody,
    String? error,
  }) => NetworkLogEntry(
    id: id,
    method: method,
    uri: uri,
    startedAt: startedAt,
    requestHeaders: requestHeaders,
    requestBody: requestBody,
    status: status,
    statusCode: statusCode,
    duration: duration,
    responseHeaders: responseHeaders ?? this.responseHeaders,
    responseBody: responseBody,
    error: error,
  );
}

final class NetworkInspectorStore extends ChangeNotifier {
  NetworkInspectorStore({this.maximumEntries = 100});

  final int maximumEntries;
  final List<NetworkLogEntry> _entries = [];

  List<NetworkLogEntry> get entries => List.unmodifiable(_entries);

  void started(NetworkLogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > maximumEntries) {
      _entries.removeRange(maximumEntries, _entries.length);
    }
    notifyListeners();
  }

  void completed(String id, NetworkLogEntry Function(NetworkLogEntry) update) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    _entries[index] = update(_entries[index]);
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

final class NetworkInspectorInterceptor extends Interceptor {
  NetworkInspectorInterceptor(this.store);

  static const _entryIdKey = 'mediguide.network_entry_id';
  static const _startedAtKey = 'mediguide.network_started_at';
  final NetworkInspectorStore store;
  int _sequence = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final startedAt = DateTime.now();
    final id = '${startedAt.microsecondsSinceEpoch}-${_sequence++}';
    options.extra[_entryIdKey] = id;
    options.extra[_startedAtKey] = startedAt;
    store.started(
      NetworkLogEntry(
        id: id,
        method: options.method.toUpperCase(),
        uri: _redactUri(options.uri),
        startedAt: startedAt,
        requestHeaders: _redactMap(options.headers),
        requestBody: _displayValue(options.data),
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final id = options.extra[_entryIdKey] as String?;
    final startedAt = options.extra[_startedAtKey] as DateTime?;
    if (id != null) {
      store.completed(
        id,
        (entry) => entry.complete(
          status: NetworkLogStatus.success,
          statusCode: response.statusCode,
          duration: startedAt == null
              ? null
              : DateTime.now().difference(startedAt),
          responseHeaders: _redactMap(response.headers.map),
          responseBody: _displayValue(response.data),
        ),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final id = options.extra[_entryIdKey] as String?;
    final startedAt = options.extra[_startedAtKey] as DateTime?;
    if (id != null) {
      store.completed(
        id,
        (entry) => entry.complete(
          status: NetworkLogStatus.failure,
          statusCode: err.response?.statusCode,
          duration: startedAt == null
              ? null
              : DateTime.now().difference(startedAt),
          responseHeaders: _redactMap(err.response?.headers.map ?? const {}),
          responseBody: _displayValue(err.response?.data),
          error: err.message,
        ),
      );
    }
    handler.next(err);
  }

  static Map<String, dynamic> _redactMap(Map<dynamic, dynamic> value) =>
      value.map(
        (key, item) => MapEntry(
          '$key',
          _isSensitiveKey('$key') ? '<redacted>' : _redact(item),
        ),
      );

  static Uri _redactUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: uri.queryParameters.map(
        (key, value) =>
            MapEntry(key, _isSensitiveKey(key) ? '<redacted>' : value),
      ),
    );
  }

  static dynamic _redact(dynamic value, [String? key]) {
    if (key != null && _isSensitiveKey(key)) {
      return '<redacted>';
    }
    if (value is Map) {
      return value.map(
        (itemKey, item) => MapEntry('$itemKey', _redact(item, '$itemKey')),
      );
    }
    if (value is Iterable) return value.map((item) => _redact(item)).toList();
    return value;
  }

  static String? _displayValue(dynamic value) {
    if (value == null) return null;
    final redacted = _redact(value);
    String rendered;
    try {
      rendered = const JsonEncoder.withIndent('  ').convert(redacted);
    } catch (_) {
      rendered = '$redacted';
    }
    const maximumLength = 20000;
    return rendered.length <= maximumLength
        ? rendered
        : '${rendered.substring(0, maximumLength)}\n… truncated';
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return normalized == 'authorization' ||
        normalized == 'cookie' ||
        normalized == 'setcookie' ||
        normalized == 'apikey' ||
        normalized.contains('password') ||
        normalized.endsWith('token') ||
        normalized.endsWith('secret');
  }
}
