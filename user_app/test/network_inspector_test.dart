import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/debug/network_inspector.dart';

final class _SuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"access_token":"response-secret","ok":true}',
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      'set-cookie': ['private-cookie'],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('records requests and recursively redacts sensitive values', () async {
    final store = NetworkInspectorStore();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _SuccessAdapter()
      ..interceptors.add(NetworkInspectorInterceptor(store));

    await dio.post<void>(
      '/login',
      queryParameters: {'accessToken': 'query-secret', 'page': 1},
      data: {
        'email': 'clinician@example.test',
        'password': 'request-secret',
        'nested': {'refresh_token': 'nested-secret'},
      },
      options: Options(headers: {'Authorization': 'Bearer header-secret'}),
    );

    final entry = store.entries.single;
    expect(entry.status, NetworkLogStatus.success);
    expect(entry.statusCode, 200);
    expect(entry.uri.toString(), contains('%3Credacted%3E'));
    expect(entry.requestHeaders['Authorization'], '<redacted>');
    expect(entry.requestBody, contains('<redacted>'));
    expect(entry.requestBody, isNot(contains('request-secret')));
    expect(entry.requestBody, isNot(contains('nested-secret')));
    expect(entry.responseBody, isNot(contains('response-secret')));
    expect(entry.responseHeaders['set-cookie'], '<redacted>');
  });

  test('retains only the configured number of entries', () {
    final store = NetworkInspectorStore(maximumEntries: 2);
    for (var index = 0; index < 3; index++) {
      store.started(
        NetworkLogEntry(
          id: '$index',
          method: 'GET',
          uri: Uri.parse('https://api.example.test/$index'),
          startedAt: DateTime(2026),
          requestHeaders: const {},
          requestBody: null,
        ),
      );
    }
    expect(store.entries.map((entry) => entry.id), ['2', '1']);
  });
}
