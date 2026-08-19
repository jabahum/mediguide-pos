import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/network/api_exception.dart';
import 'package:user_app/core/network/auth_interceptor.dart';
import 'package:user_app/core/debug/network_inspector.dart';
import 'package:user_app/core/storage/secure_storage_service.dart';

import 'package:user_app/shared/models/models.dart';

export 'api_exception.dart';

class BackendApiService {
  BackendApiService({
    Dio? dio,
    SecureStorageService? secureStorage,
    NetworkInspectorStore? networkInspector,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: mediguideApiBaseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 45),
               validateStatus: (_) => true,
             ),
           ),
       _secureStorage = secureStorage ?? SecureStorageService() {
    if (networkInspector != null) {
      _dio.interceptors.add(NetworkInspectorInterceptor(networkInspector));
    }
    _dio.interceptors.add(AuthInterceptor(accessToken: () => _accessToken));
  }

  static const _refreshTokenKey = 'backend_refresh_token';
  static const _sessionIdKey = 'backend_session_id';

  final Dio _dio;
  final SecureStorageService _secureStorage;

  final ValueNotifier<bool> schemaLoaded = ValueNotifier(false);
  final ValueNotifier<int> sessionExpired = ValueNotifier<int>(0);

  late SharedPreferences _prefs;
  String _accessToken = '';
  String _refreshToken = '';
  String _sessionId = '';
  Future<void>? _refreshInFlight;

  Future<BackendApiService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accessToken = await _readAndMigrateCredential(
      SharedPreferencesKeys.userToken,
    );
    _refreshToken = await _readAndMigrateCredential(_refreshTokenKey);
    _sessionId = await _readAndMigrateCredential(_sessionIdKey);

    schemaLoaded.value = true;
    return this;
  }

  bool get isAuthenticated => _accessToken.isNotEmpty;
  String get accessToken => _accessToken;

  Future<User> register({
    required String email,
    required String password,
    required String passwordConfirm,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = _normalizeOutgoingPayload({
      'email': email,
      'password': password,
      ...?additionalData,
    });

    final specialization = payload['specialization'];
    if (specialization is String && specialization.trim().isNotEmpty) {
      payload['specialization'] = [specialization.trim()];
    }

    await _requestJson(
      '/api/v2/auth/register',
      method: 'POST',
      body: payload,
      includeAuth: false,
    );

    return login(email: email, password: password);
  }

  Future<User> login({
    required String email,
    required String password,
    String? expand,
  }) async {
    final response = await _requestJson(
      '/api/v2/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
      includeAuth: false,
    );

    final data = _unwrapData(response);
    await _persistSession(data);

    return User.fromJson(_asMap(data['user']));
  }

  Future<User> loginWithOAuth2({
    required String provider,
    required Future<void> Function(Uri url) urlCallback,
  }) async {
    throw Exception('OAuth sign-in is not supported by the backend API');
  }

  Future<User> loginWithGoogle() async {
    throw Exception('Google sign-in is not supported by the backend API');
  }

  Future<List<String>> getAuthMethods() async => const ['password'];

  Future<void> refreshAuth() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _performRefresh();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<void> _performRefresh() async {
    if (_refreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    final response = await _requestJson(
      '/api/v2/auth/refresh',
      method: 'POST',
      body: {'refresh_token': _refreshToken},
      includeAuth: false,
    );

    await _persistSession(_unwrapData(response));
  }

  Future<void> logout() async {
    try {
      if (_accessToken.isNotEmpty) {
        await _requestJson('/api/v2/auth/logout', method: 'POST');
      }
    } finally {
      _accessToken = '';
      _refreshToken = '';
      _sessionId = '';
      await Future.wait([
        _secureStorage.delete(SharedPreferencesKeys.userToken),
        _secureStorage.delete(_refreshTokenKey),
        _secureStorage.delete(_sessionIdKey),
      ]);
      await _prefs.remove(SharedPreferencesKeys.userId);
    }
  }

  Future<Map<String, dynamic>> callCustomEndpoint({
    required String path,
    required String method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool forceRefresh = false,
  }) {
    return _requestJson(
      _normalizeCustomPath(path),
      method: method.toUpperCase(),
      body: body,
      query: query?.map((key, value) => MapEntry(key, '$value')),
      extraHeaders: headers,
    );
  }

  Future<Map<String, dynamic>> getCustomEndpoint({
    required String path,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool forceRefresh = false,
  }) {
    return callCustomEndpoint(
      path: path,
      method: 'GET',
      query: query,
      headers: headers,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> postCustomEndpoint({
    required String path,
    required Map<String, dynamic> body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return callCustomEndpoint(
      path: path,
      method: 'POST',
      body: body,
      query: query,
      headers: headers,
    );
  }

  String getFileUrl({required String filename}) {
    final trimmed = filename.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return '$mediguideApiBaseUrl$trimmed';
    }

    if (trimmed.contains('/')) {
      return '$mediguideApiBaseUrl/$trimmed';
    }

    return '';
  }

  Future<bool> checkConnection() async {
    try {
      final response = await _requestJson(
        '/api/healthz',
        method: 'GET',
        includeAuth: false,
      );
      return response['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
    bool includeAuth = true,
    bool retryAfterRefresh = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method.toUpperCase(),
          headers: headers,
          extra: {'includeAuth': includeAuth},
        ),
      );
    } on DioException catch (error) {
      throw BackendApiException(
        error.message ?? 'Unable to reach the MediGuide API.',
        statusCode: error.response?.statusCode ?? 0,
        cause: error,
      );
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode == 204) {
      return const <String, dynamic>{'success': true};
    }

    final decoded = response.data;

    final map = decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'data': decoded};

    if (statusCode == 401 &&
        includeAuth &&
        retryAfterRefresh &&
        _refreshToken.isNotEmpty) {
      try {
        await refreshAuth();
      } on BackendApiException catch (error) {
        if (error.statusCode == 401) {
          await _clearLocalSession();
          sessionExpired.value++;
        }
        rethrow;
      }
      return _requestJson(
        path,
        method: method,
        body: body,
        query: query,
        extraHeaders: extraHeaders,
        includeAuth: includeAuth,
        retryAfterRefresh: false,
      );
    }

    if (statusCode == 401 && includeAuth) {
      await _clearLocalSession();
      sessionExpired.value++;
    }

    if (statusCode >= 400 || map['success'] == false) {
      throw BackendApiException(
        _extractErrorMessage(map),
        statusCode: statusCode,
        retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
      );
    }

    return map;
  }

  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) {
    return _requestJson(
      path,
      method: method,
      body: body,
      query: query,
      includeAuth: includeAuth,
    );
  }

  Future<String> requestText(String path) async {
    final response = await _dio.get<String>(
      path,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Accept': 'text/html,application/json'},
      ),
    );
    final statusCode = response.statusCode ?? 0;
    if (statusCode >= 400) {
      throw BackendApiException(
        'Failed to load calculator content ($statusCode)',
        statusCode: statusCode,
        retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
      );
    }
    return response.data ?? '';
  }

  Future<void> _persistSession(Map<String, dynamic> data) async {
    _accessToken = data['token']?.toString() ?? '';
    _refreshToken = data['refresh_token']?.toString() ?? '';
    _sessionId = data['session_id']?.toString() ?? '';

    await Future.wait([
      _secureStorage.write(SharedPreferencesKeys.userToken, _accessToken),
      _secureStorage.write(_refreshTokenKey, _refreshToken),
      _secureStorage.write(_sessionIdKey, _sessionId),
    ]);

    final user = _asMap(data['user']);
    final userId = user['id']?.toString();
    if (userId != null && userId.isNotEmpty) {
      await _prefs.setString(SharedPreferencesKeys.userId, userId);
    }
  }

  Future<void> _clearLocalSession() async {
    _accessToken = '';
    _refreshToken = '';
    _sessionId = '';
    await Future.wait([
      _secureStorage.delete(SharedPreferencesKeys.userToken),
      _secureStorage.delete(_refreshTokenKey),
      _secureStorage.delete(_sessionIdKey),
    ]);
    await _prefs.remove(SharedPreferencesKeys.userId);
  }

  Future<String> _readAndMigrateCredential(String key) async {
    final secured = await _secureStorage.read(key);
    if (secured != null && secured.isNotEmpty) return secured;

    final legacy = _prefs.getString(key) ?? '';
    if (legacy.isEmpty) return '';
    await _secureStorage.write(key, legacy);
    await _prefs.remove(key);
    return legacy;
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final raw = response['data'];
    return raw is Map<String, dynamic> ? raw : response;
  }

  Map<String, dynamic> _normalizeOutgoingPayload(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value == null) {
        return;
      }

      final normalizedKey = switch (key) {
        'passwordConfirm' => 'password_confirm',
        'preferredLanguage' => 'preferred_language',
        'alternativePhone' => 'alternative_phone',
        'postalCode' => 'postal_code',
        'licenseNumber' => 'license_number',
        'jobTitle' => 'job_title',
        'facilityId' => 'facility_id',
        'emailVisibility' => 'email_visibility',
        'isVerified' => 'is_verified',
        'usageCount' => 'usage_count',
        'backgroundColor' => 'background_color',
        'appFile' => 'app_file',
        'addedBy' => 'added_by',
        'totalConsultations' => 'total_consultations',
        'yearsOfExperience' => 'years_of_experience',
        'consultationTypes' => 'consultation_types',
        'parentCategory' => 'parent_category',
        _ => _toSnakeCase(key),
      };

      normalized[normalizedKey] = value;
    });

    return normalized;
  }

  String _extractErrorMessage(Map<String, dynamic> response) {
    if (response['error'] != null) {
      return response['error'].toString();
    }

    final data = response['data'];
    if (data is Map<String, dynamic> && data['error'] != null) {
      return data['error'].toString();
    }

    return 'Request failed';
  }

  String _normalizeCustomPath(String path) {
    return switch (path) {
      '/api/stats' => '/api/v1/stats',
      '/api/consultants/tree' => '/api/v1/consultants/tree',
      '/api/health-facilities/tree' => '/api/v1/health-facilities/tree',
      '/api/ministry-directory/tree' => '/api/v1/ministry-directory/tree',
      '/api/overview' => '/api/v1/overview',
      _ => path,
    };
  }

  String _toSnakeCase(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAll('-', '_')
        .toLowerCase();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}

Duration? _parseRetryAfter(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final seconds = int.tryParse(value.trim());
  if (seconds != null && seconds >= 0) return Duration(seconds: seconds);
  final date = DateTime.tryParse(value);
  if (date == null) return null;
  final difference = date.toUtc().difference(DateTime.now().toUtc());
  return difference.isNegative ? Duration.zero : difference;
}
