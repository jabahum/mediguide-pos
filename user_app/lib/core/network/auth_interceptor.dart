import 'package:dio/dio.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required String Function() accessToken})
    : _accessToken = accessToken;

  final String Function() _accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _accessToken();
    if (token.isNotEmpty && options.extra['includeAuth'] != false) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
