import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/utils/constants.dart';

import '../models/models.dart';

class BackendApiException implements Exception {
  BackendApiException(
    this.message, {
    required this.statusCode,
    this.retryAfter,
  });

  final String message;
  final int statusCode;
  final Duration? retryAfter;

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() {
    if (isRateLimited && retryAfter != null) {
      return '$message Try again in ${retryAfter!.inSeconds} seconds.';
    }
    return message;
  }
}

class BackendApiService {
  static const _refreshTokenKey = 'backend_refresh_token';
  static const _sessionIdKey = 'backend_session_id';

  final ValueNotifier<bool> schemaLoaded = ValueNotifier(false);

  late SharedPreferences _prefs;
  String _accessToken = '';
  String _refreshToken = '';
  String _sessionId = '';
  Future<void>? _refreshInFlight;

  Future<BackendApiService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accessToken = _prefs.getString(SharedPreferencesKeys.userToken) ?? '';
    _refreshToken = _prefs.getString(_refreshTokenKey) ?? '';
    _sessionId = _prefs.getString(_sessionIdKey) ?? '';

    schemaLoaded.value = true;
    return this;
  }

  bool get isAuthenticated => _accessToken.isNotEmpty;
  String get accessToken => _accessToken;

  Future<ApiRecord> register({
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

  Future<ApiRecord> login({
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

    final user = _normalizeUserRecord(_asMap(data['user']));
    return ApiRecord(user);
  }

  Future<ApiRecord> loginWithOAuth2({
    required String provider,
    required Future<void> Function(Uri url) urlCallback,
  }) async {
    throw Exception('OAuth sign-in is not supported by the backend API');
  }

  Future<ApiRecord> loginWithGoogle() async {
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
      await _prefs.remove(SharedPreferencesKeys.userToken);
      await _prefs.remove(_refreshTokenKey);
      await _prefs.remove(_sessionIdKey);
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

  String getFileUrl({
    ApiRecord? record,
    String? collectionName,
    String? recordId,
    required String filename,
    String? thumb,
  }) {
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

    if (collectionName != null && recordId != null) {
      return '$mediguideApiBaseUrl/api/files/$collectionName/$recordId/$trimmed';
    }

    if (record != null) {
      return '$mediguideApiBaseUrl/api/files/${record.collectionName}/${record.id}/$trimmed';
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
    final uri = Uri.parse(mediguideApiBaseUrl).replace(
      path: _joinPath(Uri.parse(mediguideApiBaseUrl).path, path),
      queryParameters: query == null || query.isEmpty ? null : query,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (includeAuth && _accessToken.isNotEmpty)
        'Authorization': 'Bearer $_accessToken',
      ...?extraHeaders,
    };

    http.Response response;
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 204) {
      return const <String, dynamic>{'success': true};
    }

    final decoded = response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));

    final map = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode == 401 &&
        includeAuth &&
        retryAfterRefresh &&
        _refreshToken.isNotEmpty) {
      await refreshAuth();
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

    if (response.statusCode >= 400 || map['success'] == false) {
      throw BackendApiException(
        _extractErrorMessage(map),
        statusCode: response.statusCode,
        retryAfter: _parseRetryAfter(response.headers['retry-after']),
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
    final base = Uri.parse(mediguideApiBaseUrl);
    final uri = base.replace(path: _joinPath(base.path, path));
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'text/html,application/json',
        if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
      },
    );
    if (response.statusCode >= 400) {
      throw BackendApiException(
        'Failed to load calculator content (${response.statusCode})',
        statusCode: response.statusCode,
        retryAfter: _parseRetryAfter(response.headers['retry-after']),
      );
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<void> _persistSession(Map<String, dynamic> data) async {
    _accessToken = data['token']?.toString() ?? '';
    _refreshToken = data['refresh_token']?.toString() ?? '';
    _sessionId = data['session_id']?.toString() ?? '';

    await _prefs.setString(SharedPreferencesKeys.userToken, _accessToken);
    await _prefs.setString(_refreshTokenKey, _refreshToken);
    await _prefs.setString(_sessionIdKey, _sessionId);

    final user = _asMap(data['user']);
    final userId = user['id']?.toString();
    if (userId != null && userId.isNotEmpty) {
      await _prefs.setString(SharedPreferencesKeys.userId, userId);
    }
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

  Map<String, dynamic> _normalizeUserRecord(Map<String, dynamic> raw) {
    final data = <String, dynamic>{};
    raw.forEach((key, value) {
      data[key] = value;
      if (key.endsWith('_json')) {
        final alias = key.substring(0, key.length - 5);
        data[alias] = value;
        data[_toCamelCase(alias)] = value;
      }
      if (key.contains('_')) {
        data[_toCamelCase(key)] = value;
      }
    });

    data['id'] = raw['id']?.toString() ?? '';
    data['collectionName'] = User.collection;
    data['collectionId'] = User.collection;
    data['created'] =
        raw['created']?.toString() ?? raw['created_at']?.toString() ?? '';
    data['updated'] =
        raw['updated']?.toString() ?? raw['updated_at']?.toString() ?? '';

    final roles = raw['roles'];
    if (raw['role'] == null && roles is List && roles.isNotEmpty) {
      final first = _asMap(roles.first);
      data['role'] =
          first['role_key']?.toString() ?? first['name']?.toString() ?? '';
    }
    return data;
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

  String _joinPath(String basePath, String nextPath) {
    final left = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final right = nextPath.startsWith('/') ? nextPath : '/$nextPath';
    return '$left$right';
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

  String _toCamelCase(String value) {
    final parts = value.split('_');
    if (parts.isEmpty) {
      return value;
    }

    return parts.first +
        parts.skip(1).map((part) {
          if (part.isEmpty) {
            return '';
          }
          return part[0].toUpperCase() + part.substring(1);
        }).join();
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
