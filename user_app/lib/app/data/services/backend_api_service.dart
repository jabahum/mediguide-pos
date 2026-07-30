import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/utils/constants.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'main_service.dart';

class BackendApiService extends GetxService {
  static BackendApiService get to => Get.find();

  static const _refreshTokenKey = 'backend_refresh_token';
  static const _sessionIdKey = 'backend_session_id';
  static const _readingProgressKey = 'local_reading_progress_records';

  final Map<String, Function> _subscriptions = {};
  final RxBool schemaLoaded = false.obs;

  late SharedPreferences _prefs;
  String _accessToken = '';
  String _refreshToken = '';
  String _sessionId = '';

  Future<BackendApiService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accessToken = _prefs.getString(SharedPreferencesKeys.userToken) ?? '';
    _refreshToken = _prefs.getString(_refreshTokenKey) ?? '';
    _sessionId = _prefs.getString(_sessionIdKey) ?? '';

    ever(MainService.to.isOnline, (bool online) {
      if (online) {
        unawaited(_onReconnect());
      }
    });

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

    final user = _normalizeRecord(
      collectionName: User.collection,
      raw: _asMap(data['user']),
    );
    return ApiRecord(user);
  }

  Future<ApiRecord> updateCurrentUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final response = await _requestJson(
      '/api/v2/users/$userId',
      method: 'PATCH',
      body: _normalizeOutgoingPayload(data),
    );
    return ApiRecord(
      _normalizeRecord(
        collectionName: User.collection,
        raw: _unwrapData(response),
      ),
    );
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

  Future<void> requestPasswordReset(String email) async {
    throw Exception('Password reset is not exposed by the backend API');
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    throw Exception(
      'Password reset confirmation is not exposed by the backend API',
    );
  }

  Future<void> confirmEmailVerification(String token) async {
    throw Exception('Email verification is not exposed by the backend API');
  }

  Future<void> refreshAuth() async {
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    await login(email: currentUser.email, password: currentPassword);

    await updateResource(
      collectionName: User.collection,
      recordId: currentUser.id,
      data: {'password': newPassword, 'passwordConfirm': newPasswordConfirm},
    );
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

  Future<PagedResult<ApiRecord>> getCalculators({
    int page = 1,
    int perPage = 30,
    String? search,
    List<String> types = const [],
    List<String> statuses = const [],
    bool? featured,
    String sort = '-created',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 1 : perPage;
    final response = await _requestJson(
      '/api/v2/calculators',
      method: 'GET',
      query: {
        'page': '$safePage',
        'per_page': '$safePerPage',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (types.isNotEmpty) 'type': types.join(','),
        if (statuses.isNotEmpty) 'status': statuses.join(','),
        if (featured != null) 'featured': '$featured',
        'sort': sort,
      },
    );
    final data = _unwrapData(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => ApiRecord(
            _normalizeRecord(
              collectionName: Calculator.collection,
              raw: _asMap(item),
            ),
          ),
        )
        .toList();
    return PagedResult<ApiRecord>(
      page: (data['page'] as num?)?.toInt() ?? safePage,
      perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<String> getCalculatorContent(String calculatorId) {
    return _requestText('/api/v2/calculators/$calculatorId/content');
  }

  String getCalculatorContentUrl(String calculatorId) =>
      '${mediguideApiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/api/v2/calculators/$calculatorId/content';

  Future<ApiRecord> startCalculatorUsage({
    required String calculatorId,
    required String sessionStart,
    required String calculatorType,
  }) async {
    final response = await _requestJson(
      '/api/v2/calculators/$calculatorId/usage',
      method: 'POST',
      body: {'session_start': sessionStart, 'calculator_type': calculatorType},
    );
    return ApiRecord(
      _normalizeRecord(
        collectionName: CalculatorUsageLog.collection,
        raw: _unwrapData(response),
      ),
    );
  }

  Future<ApiRecord> finishCalculatorUsage({
    required String usageId,
    required String sessionEnd,
  }) async {
    final response = await _requestJson(
      '/api/v2/calculator-usage/$usageId',
      method: 'PATCH',
      body: {'session_end': sessionEnd},
    );
    return ApiRecord(
      _normalizeRecord(
        collectionName: CalculatorUsageLog.collection,
        raw: _unwrapData(response),
      ),
    );
  }

  Future<PagedResult<ApiRecord>> getDrugs({
    int page = 1,
    int perPage = 30,
    String? search,
    String? status,
    String? reviewStatus,
    String? drugClassId,
    String? therapeuticCategoryId,
    String? route,
    String? pregnancyCategory,
    bool? whoEml,
    bool? antimicrobial,
    String sort = 'name',
    String order = 'asc',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 1 : perPage;
    final response = await _requestJson(
      '/api/v2/drugs',
      method: 'GET',
      query: {
        'page': '$safePage',
        'per_page': '$safePerPage',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (reviewStatus != null && reviewStatus.trim().isNotEmpty)
          'review_status': reviewStatus.trim(),
        if (drugClassId != null && drugClassId.trim().isNotEmpty)
          'drug_class_id': drugClassId.trim(),
        if (therapeuticCategoryId != null &&
            therapeuticCategoryId.trim().isNotEmpty)
          'therapeutic_category_id': therapeuticCategoryId.trim(),
        if (route != null && route.trim().isNotEmpty) 'route': route.trim(),
        if (pregnancyCategory != null && pregnancyCategory.trim().isNotEmpty)
          'pregnancy_category': pregnancyCategory.trim(),
        if (whoEml != null) 'who_eml': '$whoEml',
        if (antimicrobial != null) 'antimicrobial': '$antimicrobial',
        'sort': sort,
        'order': order,
      },
    );
    final data = _unwrapData(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => ApiRecord(
            _normalizeRecord(
              collectionName: Drug.collection,
              raw: _asMap(item),
            ),
          ),
        )
        .toList();
    return PagedResult<ApiRecord>(
      page: (data['page'] as num?)?.toInt() ?? safePage,
      perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<ApiRecord?> getDrug(String drugId) async {
    try {
      final response = await _requestJson(
        '/api/v2/drugs/$drugId',
        method: 'GET',
      );
      return ApiRecord(
        _normalizeRecord(
          collectionName: Drug.collection,
          raw: _unwrapData(response),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ApiRecord> recordDrugUsage(String drugId) async {
    final response = await _requestJson(
      '/api/v2/drugs/$drugId/usage',
      method: 'POST',
    );
    return ApiRecord(
      _normalizeRecord(
        collectionName: DrugUsageLog.collection,
        raw: _unwrapData(response),
      ),
    );
  }

  Future<ApiRecord> createResource({
    required String collectionName,
    required Map<String, dynamic> data,
    List<http.MultipartFile>? files,
  }) async {
    if (collectionName == 'reading_progress') {
      return _createLocalReadingProgress(data);
    }

    if (files != null && files.isNotEmpty) {
      throw Exception('File uploads are not supported by the backend API');
    }
    final typedPath = _typedCollectionPath(collectionName);
    if (typedPath == null) {
      throw Exception(
        'No typed backend endpoint is registered for $collectionName',
      );
    }
    final response = await _requestJson(
      typedPath,
      method: 'POST',
      body: _normalizeOutgoingPayload(data),
    );

    final item = _asMap(response['item'] ?? _unwrapData(response));
    return ApiRecord(
      _normalizeRecord(collectionName: collectionName, raw: item),
    );
  }

  Future<PagedResult<ApiRecord>> getResourceList({
    required String collectionName,
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
    String? expand,
    bool forceRefresh = false,
  }) async {
    if (collectionName == 'reading_progress') {
      return _listLocalReadingProgress(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort,
      );
    }
    if (collectionName == Drug.collection) {
      return getDrugs(page: page, perPage: perPage);
    }

    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 1 : perPage;
    final typedPath = _typedCollectionPath(collectionName);
    if (typedPath == null) {
      throw Exception(
        'No typed backend endpoint is registered for $collectionName',
      );
    }
    final response = await _requestJson(
      typedPath,
      method: 'GET',
      query: {
        'page': '$safePage',
        'per_page': '$safePerPage',
        ..._structuredQueryFromLegacyArguments(filter: filter, sort: sort),
      },
    );

    final responseData = _unwrapData(response);
    final rawItems = (responseData['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          return _normalizeRecord(
            collectionName: collectionName,
            raw: _asMap(item),
          );
        })
        .toList();

    final totalItems =
        (responseData['total_items'] as num?)?.toInt() ??
        (responseData['totalItems'] as num?)?.toInt() ??
        rawItems.length;
    final totalPages =
        (responseData['total_pages'] as num?)?.toInt() ??
        (responseData['totalPages'] as num?)?.toInt() ??
        (totalItems == 0 ? 0 : (totalItems / safePerPage).ceil());

    return PagedResult<ApiRecord>(
      page: safePage,
      perPage: safePerPage,
      totalItems: totalItems,
      totalPages: totalPages,
      items: rawItems.map(ApiRecord.new).toList(),
    );
  }

  Future<List<ApiRecord>> getFullResourceList({
    required String collectionName,
    int batch = 100,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    final result = await getResourceList(
      collectionName: collectionName,
      page: 1,
      perPage: batch,
      filter: filter,
      sort: sort,
      expand: expand,
    );
    return result.items;
  }

  Future<ApiRecord?> getResource({
    required String collectionName,
    required String recordId,
    String? expand,
    bool forceRefresh = false,
  }) async {
    if (collectionName == 'reading_progress') {
      return _getLocalReadingProgress(recordId);
    }

    try {
      final typedPath = _typedCollectionPath(collectionName);
      if (typedPath == null) {
        throw Exception(
          'No typed backend endpoint is registered for $collectionName',
        );
      }
      final response = await _requestJson(
        '$typedPath/$recordId',
        method: 'GET',
      );

      final item = _asMap(response['item'] ?? _unwrapData(response));
      return ApiRecord(
        _normalizeRecord(collectionName: collectionName, raw: item),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ApiRecord> getFirstResourceItem({
    required String collectionName,
    required String filter,
    String? expand,
  }) async {
    final result = await getResourceList(
      collectionName: collectionName,
      page: 1,
      perPage: 1,
      filter: filter,
      expand: expand,
    );

    if (result.items.isEmpty) {
      throw Exception('No records found');
    }

    return result.items.first;
  }

  Future<ApiRecord> updateResource({
    required String collectionName,
    required String recordId,
    required Map<String, dynamic> data,
    List<http.MultipartFile>? files,
  }) async {
    if (collectionName == 'reading_progress') {
      return _updateLocalReadingProgress(recordId, data);
    }

    if (files != null && files.isNotEmpty) {
      throw Exception('File uploads are not supported by the backend API');
    }

    final typedPath = _typedCollectionPath(collectionName);
    if (typedPath == null) {
      throw Exception(
        'No typed backend endpoint is registered for $collectionName',
      );
    }
    final response = await _requestJson(
      '$typedPath/$recordId',
      method: 'PATCH',
      body: _normalizeOutgoingPayload(data),
    );

    final item = _asMap(response['item'] ?? _unwrapData(response));
    return ApiRecord(
      _normalizeRecord(collectionName: collectionName, raw: item),
    );
  }

  Future<void> deleteResource({
    required String collectionName,
    required String recordId,
  }) async {
    if (collectionName == 'reading_progress') {
      final rows = await _readLocalReadingProgress();
      rows.removeWhere((row) => row['id'] == recordId);
      await _writeLocalReadingProgress(rows);
      return;
    }

    final typedPath = _typedCollectionPath(collectionName);
    if (typedPath == null) {
      throw Exception(
        'No typed backend endpoint is registered for $collectionName',
      );
    }
    await _requestJson('$typedPath/$recordId', method: 'DELETE');
  }

  Future<ApiRecord> upsertResource({
    required String collectionName,
    required Map<String, dynamic> data,
    String idField = 'id',
    List<http.MultipartFile>? files,
  }) async {
    final recordId = data[idField]?.toString();
    if (recordId != null && recordId.isNotEmpty) {
      final existing = await getResource(
        collectionName: collectionName,
        recordId: recordId,
      );
      if (existing != null) {
        return updateResource(
          collectionName: collectionName,
          recordId: recordId,
          data: data,
          files: files,
        );
      }
    }

    return createResource(
      collectionName: collectionName,
      data: data,
      files: files,
    );
  }

  Future<List<dynamic>> batchOperation(
    List<Map<String, dynamic>> operations,
  ) async {
    final results = <dynamic>[];

    for (final operation in operations) {
      final type = operation['type']?.toString() ?? '';
      final collection = operation['collection']?.toString() ?? '';

      switch (type) {
        case 'create':
          results.add(
            await createResource(
              collectionName: collection,
              data: Map<String, dynamic>.from(operation['data'] as Map),
            ),
          );
          break;
        case 'update':
          results.add(
            await updateResource(
              collectionName: collection,
              recordId: operation['id'].toString(),
              data: Map<String, dynamic>.from(operation['data'] as Map),
            ),
          );
          break;
        case 'delete':
          await deleteResource(
            collectionName: collection,
            recordId: operation['id'].toString(),
          );
          results.add(true);
          break;
        case 'upsert':
          results.add(
            await upsertResource(
              collectionName: collection,
              data: Map<String, dynamic>.from(operation['data'] as Map),
            ),
          );
          break;
        default:
          throw Exception('Unknown operation type: $type');
      }
    }

    return results;
  }

  void subscribeToCollection(
    String collectionName,
    Function(ApiRecordSubscriptionEvent) callback, {
    String recordId = '*',
    String? filter,
  }) {
    _subscriptions['$collectionName/$recordId'] = callback;
  }

  void unsubscribeFromCollection({
    required String collectionName,
    String recordId = '*',
  }) {
    _subscriptions.remove('$collectionName/$recordId');
  }

  void subscribeToCustomEvent({
    required String eventName,
    required Function(dynamic) callback,
  }) {
    _subscriptions[eventName] = callback;
  }

  void unsubscribeFromCustomEvent(String eventName) {
    _subscriptions.remove(eventName);
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

  void unsubscribeFromAll() {
    _subscriptions.clear();
  }

  void onDisconnect(Function(List<String>) callback) {
    callback(_subscriptions.keys.toList());
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

  Future<String> getFileToken() async => '';

  String createFilter(String filterTemplate, Map<String, dynamic> params) {
    var result = filterTemplate;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', escapeFilterValue(value));
    });
    return result;
  }

  static String escapeFilterValue(Object? value) {
    return '$value'.replaceAll('\\', '\\\\').replaceAll('"', '\\"').trim();
  }

  Future<void> _onReconnect() async {
    if (!isAuthenticated || _refreshToken.isEmpty) {
      return;
    }

    try {
      await refreshAuth();
    } catch (_) {
      // Ignore background refresh failures.
    }
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

  Future<void> incrementUsageCount(
    String collectionName,
    String recordId,
  ) async {
    // The backend API does not expose public usage counter mutation.
  }

  Future<Map<String, dynamic>> _requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
    bool includeAuth = true,
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

    if (response.statusCode >= 400 || map['success'] == false) {
      throw Exception(_extractErrorMessage(map));
    }

    return map;
  }

  Future<String> _requestText(String path) async {
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
      throw Exception(
        'Failed to load calculator content (${response.statusCode})',
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

  Map<String, dynamic> _normalizeRecord({
    required String collectionName,
    required Map<String, dynamic> raw,
  }) {
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
    data['collectionName'] = collectionName;
    data['collectionId'] = collectionName;
    data['created'] =
        raw['created']?.toString() ?? raw['created_at']?.toString() ?? '';
    data['updated'] =
        raw['updated']?.toString() ?? raw['updated_at']?.toString() ?? '';

    if (raw.containsKey('guideline_document_id')) {
      data['guideline_id'] = raw['guideline_document_id']?.toString() ?? '';
    }

    switch (collectionName) {
      case 'users':
        final roles = raw['roles'];
        if (raw['role'] == null && roles is List && roles.isNotEmpty) {
          final first = _asMap(roles.first);
          data['role'] =
              first['role_key']?.toString() ?? first['name']?.toString() ?? '';
        }
        break;
      case 'consultants':
        data['user'] = raw['user_id']?.toString() ?? '';
        _injectExpandUser(data, field: 'user', prefix: 'user_expand_');
        break;
      case 'support_ticket_replies':
        _injectExpandUser(data, field: 'user_id', prefix: 'user_expand_');
        break;
      case 'conversations':
        data['participant1'] = raw['participant1_user_id']?.toString() ?? '';
        data['participant2'] = raw['participant2_user_id']?.toString() ?? '';
        _injectExpandUser(
          data,
          field: 'participant1',
          prefix: 'participant1_expand_',
        );
        _injectExpandUser(
          data,
          field: 'participant2',
          prefix: 'participant2_expand_',
        );
        if ((raw['last_message'] ?? '').toString().isNotEmpty) {
          data['expand'] = {
            ..._asMap(data['expand']),
            'last_message': {
              'id': raw['last_message_id']?.toString() ?? '',
              'content': raw['last_message']?.toString() ?? '',
              'collectionName': 'messages',
              'collectionId': 'messages',
            },
          };
        }
        break;
      case 'messages':
        data['conversation'] = raw['conversation_id']?.toString() ?? '';
        data['sender'] = raw['sender_user_id']?.toString() ?? '';
        data['reply_to'] = raw['reply_to_id']?.toString() ?? '';
        _injectExpandUser(data, field: 'sender', prefix: 'sender_expand_');
        break;
      case 'health_facilities':
        data['facility_level'] = raw['facility_level_id']?.toString() ?? '';
        data['authority'] = raw['authority_id']?.toString() ?? '';
        data['ownership_type'] = raw['ownership_type_id']?.toString() ?? '';
        data['health_sub_district'] =
            raw['health_sub_district_id']?.toString() ?? '';
        data['parish'] = raw['parish_id']?.toString() ?? '';
        data['subcounty'] = raw['subcounty_id']?.toString() ?? '';
        data['county'] = raw['county_id']?.toString() ?? '';
        data['district'] = raw['district_id']?.toString() ?? '';
        data['region'] = raw['region_id']?.toString() ?? '';
        _injectSimpleExpand(
          data,
          field: 'facility_level',
          id: data['facility_level']?.toString() ?? '',
          collectionName: 'facility_levels',
          extra: {'name': raw['facility_level_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'authority',
          id: data['authority']?.toString() ?? '',
          collectionName: 'authorities',
          extra: {'name': raw['authority_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'ownership_type',
          id: data['ownership_type']?.toString() ?? '',
          collectionName: 'ownership_types',
          extra: {'name': raw['ownership_type_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'health_sub_district',
          id: data['health_sub_district']?.toString() ?? '',
          collectionName: 'health_sub_districts',
          extra: {'name': raw['health_sub_district_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'parish',
          id: data['parish']?.toString() ?? '',
          collectionName: 'parishes',
          extra: {'name': raw['parish_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'subcounty',
          id: data['subcounty']?.toString() ?? '',
          collectionName: 'subcounties',
          extra: {'name': raw['subcounty_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'county',
          id: data['county']?.toString() ?? '',
          collectionName: 'counties',
          extra: {'name': raw['county_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'district',
          id: data['district']?.toString() ?? '',
          collectionName: 'districts',
          extra: {'name': raw['district_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'region',
          id: data['region']?.toString() ?? '',
          collectionName: 'regions',
          extra: {'name': raw['region_name']},
        );
        break;
      case 'ministry_directory':
        data['district'] = raw['district_id']?.toString() ?? '';
        data['region'] = raw['region_id']?.toString() ?? '';
        _injectSimpleExpand(
          data,
          field: 'district',
          id: data['district']?.toString() ?? '',
          collectionName: 'districts',
          extra: {'name': raw['district_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'region',
          id: data['region']?.toString() ?? '',
          collectionName: 'regions',
          extra: {'name': raw['region_name']},
        );
        break;
      case 'calculators':
        data['addedBy'] = raw['added_by_user_id']?.toString() ?? '';
        data['backgroundColor'] = raw['background_color']?.toString() ?? '';
        final appFile =
            _extractJsonPath(raw['app_file_json']) ??
            raw['app_file']?.toString() ??
            '';
        data['appFile'] = appFile;
        data['app_file'] = appFile;
        break;
      case 'guideline_index':
        data['parent'] = raw['parent_id']?.toString() ?? '';
        data['hasChildren'] = raw['has_children'] ?? false;
        data['order'] = raw['sort_order'] ?? 0;
        break;
      case 'guideline_categories':
        data['parent_category'] = raw['parent_category_id']?.toString() ?? '';
        break;
      case 'guidelines':
      case 'medical_guidelines':
        data['index_item'] = raw['index_item_id']?.toString() ?? '';
        if ((raw['index_item_title'] ?? '').toString().isNotEmpty) {
          _injectSimpleExpand(
            data,
            field: 'index_item',
            id: data['index_item']?.toString() ?? '',
            collectionName: 'guideline_index',
            extra: {'title': raw['index_item_title']},
          );
        }
        break;
      case 'abbreviations':
        data['category'] =
            raw['category_id']?.toString() ??
            raw['guideline_category_id']?.toString() ??
            '';
        break;
      case 'drugs':
        data['drug_class'] = raw['drug_class_id']?.toString() ?? '';
        data['therapeutic_category'] =
            raw['therapeutic_category_id']?.toString() ?? '';
        _injectSimpleExpand(
          data,
          field: 'drug_class',
          id: data['drug_class']?.toString() ?? '',
          collectionName: 'drug_classes',
          extra: {'name': raw['drug_class_name']},
        );
        _injectSimpleExpand(
          data,
          field: 'therapeutic_category',
          id: data['therapeutic_category']?.toString() ?? '',
          collectionName: 'therapeutic_categories',
          extra: {'name': raw['therapeutic_category_name']},
        );
        break;
    }

    return data;
  }

  void _injectExpandUser(
    Map<String, dynamic> data, {
    required String field,
    required String prefix,
  }) {
    final id =
        data['${prefix}id']?.toString() ??
        data['${prefix}id'.replaceAll('_', '')]?.toString() ??
        '';
    final rawId = data['${prefix}id'];
    final resolvedId = (rawId ?? id).toString();
    if (resolvedId.isEmpty) {
      return;
    }

    _injectSimpleExpand(
      data,
      field: field,
      id: resolvedId,
      collectionName: 'users',
      extra: {
        'name': data['${prefix}name'],
        'email': data['${prefix}email'],
        'avatar': data['${prefix}avatar'],
        'verified': data['${prefix}verified'],
      },
    );
  }

  void _injectSimpleExpand(
    Map<String, dynamic> data, {
    required String field,
    required String id,
    required String collectionName,
    required Map<String, dynamic> extra,
  }) {
    if (id.isEmpty &&
        extra.values.every((value) => value == null || '$value'.isEmpty)) {
      return;
    }

    final expand = _asMap(data['expand']);
    expand[field] = {
      'id': id,
      'collectionName': collectionName,
      'collectionId': collectionName,
      ...extra,
    };
    data['expand'] = expand;
  }

  String? _extractJsonPath(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['path']?.toString();
    }

    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded['path']?.toString();
      }
    }

    return null;
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

  List<Map<String, dynamic>> _applyClientSideFilter(
    List<Map<String, dynamic>> records,
    String? filter,
  ) {
    final expression = filter?.trim() ?? '';
    if (expression.isEmpty) {
      return records;
    }

    return records
        .where((record) => _evaluateFilter(record, expression))
        .toList();
  }

  bool _evaluateFilter(Map<String, dynamic> record, String expression) {
    final orParts = _splitExpression(expression, '||');
    for (final orPart in orParts) {
      final andParts = _splitExpression(orPart, '&&');
      if (andParts.every((part) => _evaluateCondition(record, part))) {
        return true;
      }
    }
    return false;
  }

  List<String> _splitExpression(String expression, String delimiter) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var depth = 0;
    var inQuote = false;

    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];
      final next = i + 1 < expression.length ? expression[i + 1] : '';

      if (char == '"' && !_isEscaped(expression, i)) {
        inQuote = !inQuote;
      }

      if (!inQuote) {
        if (char == '(') {
          depth++;
        } else if (char == ')') {
          depth = depth > 0 ? depth - 1 : 0;
        }
      }

      if (!inQuote && depth == 0 && char + next == delimiter) {
        final part = _trimOuterParens(buffer.toString().trim());
        if (part.isNotEmpty) {
          parts.add(part);
        }
        buffer.clear();
        i++;
        continue;
      }

      buffer.write(char);
    }

    final tail = _trimOuterParens(buffer.toString().trim());
    if (tail.isNotEmpty) {
      parts.add(tail);
    }

    return parts;
  }

  String _trimOuterParens(String value) {
    var result = value.trim();
    while (result.startsWith('(') && result.endsWith(')')) {
      var depth = 0;
      var balanced = true;
      for (var i = 0; i < result.length; i++) {
        final char = result[i];
        if (char == '(') depth++;
        if (char == ')') depth--;
        if (depth == 0 && i < result.length - 1) {
          balanced = false;
          break;
        }
      }
      if (!balanced) {
        break;
      }
      result = result.substring(1, result.length - 1).trim();
    }
    return result;
  }

  bool _isEscaped(String value, int index) {
    var slashCount = 0;
    for (var i = index - 1; i >= 0 && value[i] == '\\'; i--) {
      slashCount++;
    }
    return slashCount.isOdd;
  }

  bool _evaluateCondition(Map<String, dynamic> record, String condition) {
    final match = RegExp(
      r'^([A-Za-z0-9_\.]+)\s*(=|!=|>=|<=|>|<|~)\s*(.+)$',
    ).firstMatch(condition.trim());
    if (match == null) {
      return false;
    }

    final field = match.group(1)!.trim();
    final operator = match.group(2)!.trim();
    final rawExpected = _parseLiteral(match.group(3)!.trim());
    final actual = _lookupValue(record, field);

    switch (operator) {
      case '=':
        return _compare(actual, rawExpected) == 0;
      case '!=':
        return _compare(actual, rawExpected) != 0;
      case '>':
        return _compare(actual, rawExpected) > 0;
      case '<':
        return _compare(actual, rawExpected) < 0;
      case '>=':
        return _compare(actual, rawExpected) >= 0;
      case '<=':
        return _compare(actual, rawExpected) <= 0;
      case '~':
        return '${actual ?? ''}'.toLowerCase().contains(
          '${rawExpected ?? ''}'.toLowerCase(),
        );
      default:
        return false;
    }
  }

  dynamic _lookupValue(Map<String, dynamic> record, String field) {
    final direct = record[field];
    if (direct != null) {
      return direct;
    }

    final camel = _toCamelCase(field);
    if (record.containsKey(camel)) {
      return record[camel];
    }

    final snake = _toSnakeCase(field);
    if (record.containsKey(snake)) {
      return record[snake];
    }

    return null;
  }

  dynamic _parseLiteral(String value) {
    final trimmed = _trimOuterParens(value).trim();
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      return trimmed
          .substring(1, trimmed.length - 1)
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', '\\');
    }
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;
    if (trimmed.isEmpty) return '';
    return num.tryParse(trimmed) ?? trimmed;
  }

  int _compare(dynamic left, dynamic right) {
    if (left == null && right == null) return 0;
    if (left == null) return -1;
    if (right == null) return 1;

    final leftNum = num.tryParse('$left');
    final rightNum = num.tryParse('$right');
    if (leftNum != null && rightNum != null) {
      return leftNum.compareTo(rightNum);
    }

    if (left is bool || right is bool) {
      return ('$left').compareTo('$right');
    }

    return '$left'.toLowerCase().compareTo('$right'.toLowerCase());
  }

  List<Map<String, dynamic>> _applyClientSideSort(
    List<Map<String, dynamic>> records,
    String? sort,
  ) {
    if (sort == null || sort.trim().isEmpty) {
      return records;
    }

    final sorted = [...records];
    final sorters = sort
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    sorted.sort((a, b) {
      for (final sorter in sorters) {
        final descending = sorter.startsWith('-');
        final field = sorter.startsWith('-') || sorter.startsWith('+')
            ? sorter.substring(1)
            : sorter;
        final comparison = _compare(
          _lookupValue(a, field),
          _lookupValue(b, field),
        );
        if (comparison != 0) {
          return descending ? -comparison : comparison;
        }
      }
      return 0;
    });

    return sorted;
  }

  Future<List<Map<String, dynamic>>> _readLocalReadingProgress() async {
    final raw = _prefs.getString(_readingProgressKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }

    return decoded.whereType<Map>().map((item) => _asMap(item)).toList();
  }

  Future<void> _writeLocalReadingProgress(List<Map<String, dynamic>> rows) {
    return _prefs.setString(_readingProgressKey, jsonEncode(rows));
  }

  Future<ApiRecord> _createLocalReadingProgress(
    Map<String, dynamic> data,
  ) async {
    final rows = await _readLocalReadingProgress();
    final normalized = _normalizeOutgoingPayload(data);
    final userId = normalized['user_id']?.toString() ?? '';
    final guidelineId = normalized['guideline_id']?.toString() ?? '';

    final existingIndex = rows.indexWhere(
      (row) => row['user_id'] == userId && row['guideline_id'] == guidelineId,
    );

    final now = DateTime.now().toIso8601String();
    final record = <String, dynamic>{
      ...normalized,
      'id': existingIndex >= 0
          ? rows[existingIndex]['id']
          : DateTime.now().microsecondsSinceEpoch.toString(),
      'created': existingIndex >= 0 ? rows[existingIndex]['created'] : now,
      'updated': now,
      'collectionName': 'reading_progress',
      'collectionId': 'reading_progress',
    };

    if (existingIndex >= 0) {
      rows[existingIndex] = record;
    } else {
      rows.add(record);
    }

    await _writeLocalReadingProgress(rows);
    return ApiRecord(record);
  }

  Future<ApiRecord?> _getLocalReadingProgress(String recordId) async {
    final rows = await _readLocalReadingProgress();
    for (final row in rows) {
      if (row['id'] == recordId) {
        return ApiRecord(row);
      }
    }
    return null;
  }

  Future<ApiRecord> _updateLocalReadingProgress(
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final rows = await _readLocalReadingProgress();
    final index = rows.indexWhere((row) => row['id'] == recordId);
    if (index < 0) {
      throw Exception('Reading progress record not found');
    }

    final updated = {
      ...rows[index],
      ..._normalizeOutgoingPayload(data),
      'updated': DateTime.now().toIso8601String(),
    };

    rows[index] = updated;
    await _writeLocalReadingProgress(rows);
    return ApiRecord(updated);
  }

  Future<PagedResult<ApiRecord>> _listLocalReadingProgress({
    required int page,
    required int perPage,
    String? filter,
    String? sort,
  }) async {
    var rows = await _readLocalReadingProgress();
    rows = _applyClientSideFilter(rows, filter);
    rows = _applyClientSideSort(rows, sort);

    final totalItems = rows.length;
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 1 : perPage;
    final offset = (safePage - 1) * safePerPage;
    final paged = offset >= rows.length
        ? <Map<String, dynamic>>[]
        : rows.skip(offset).take(safePerPage).toList();
    final totalPages = totalItems == 0 ? 0 : (totalItems / safePerPage).ceil();

    return PagedResult<ApiRecord>(
      page: safePage,
      perPage: safePerPage,
      totalItems: totalItems,
      totalPages: totalPages,
      items: paged.map(ApiRecord.new).toList(),
    );
  }

  String? _typedCollectionPath(String collectionName) {
    return switch (collectionName) {
      Drug.collection => '/api/v2/drugs',
      DrugCategory.collection => '/api/v2/drug-categories',
      DrugTag.collection => '/api/v2/drug-tags',
      DrugClass.collection => '/api/v2/drug-classes',
      TherapeuticCategory.collection => '/api/v2/therapeutic-categories',
      'medical_guidelines' => '/api/v2/medical-guidelines',
      'abbreviations' => '/api/v2/abbreviations',
      'emergency_protocols' => '/api/v2/emergency-protocols',
      'faqs' => '/api/v2/faqs',
      'faq_tags' => '/api/v2/faq-tags',
      'documentation' => '/api/v2/documentation',
      'generic_pages' => '/api/v2/pages',
      'guideline_categories' => '/api/v2/guideline-categories',
      'guideline_tags' => '/api/v2/guideline-tags',
      'guideline_index' => '/api/v2/guideline-index',
      'consultants' => '/api/v2/consultants',
      'health_sub_regions' => '/api/v2/health-sub-regions',
      'health_facilities' => '/api/v2/facilities',
      'regions' => '/api/v2/regions',
      'districts' => '/api/v2/districts',
      'health_sub_districts' => '/api/v2/health-sub-districts',
      'counties' => '/api/v2/counties',
      'subcounties' => '/api/v2/subcounties',
      'parishes' => '/api/v2/parishes',
      'facility_levels' => '/api/v2/facility-levels',
      'ownership_types' => '/api/v2/ownership-types',
      'authorities' => '/api/v2/authorities',
      'ministry_directory' => '/api/v2/ministry-directory',
      'languages' => '/api/v2/reference-languages',
      'users' => '/api/v2/users',
      'roles' => '/api/v2/roles',
      'notifications' => '/api/v2/notifications',
      'notification_templates' => '/api/v2/notification-templates',
      'notification_campaigns' => '/api/v2/notification-campaigns',
      'support_tickets' => '/api/v2/support-tickets',
      'support_ticket_replies' => '/api/v2/support-ticket-replies',
      'conversations' => '/api/v2/conversations',
      'messages' => '/api/v2/messages',
      'guideline_usage_logs' => '/api/v2/guideline-usage',
      'abbreviation_usage_logs' => '/api/v2/abbreviation-usage',
      'consultant_usage_logs' => '/api/v2/consultant-usage',
      'facility_usage_logs' => '/api/v2/facility-usage',
      'ai_usage_logs' => '/api/v2/ai-usage',
      _ => null,
    };
  }

  Map<String, String> _structuredQueryFromLegacyArguments({
    String? filter,
    String? sort,
  }) {
    final query = <String, String>{};
    final expression = filter?.trim() ?? '';
    if (expression.isNotEmpty) {
      final searchMatch = RegExp(
        r'[A-Za-z0-9_]+\s*~\s*"([^"]+)"',
      ).firstMatch(expression);
      if (searchMatch != null) {
        query['search'] = searchMatch.group(1)!;
      }

      if (!expression.contains('||')) {
        final equalityPattern = RegExp(
          r'([A-Za-z0-9_]+)\s*=\s*(?:"([^"]*)"|([A-Za-z0-9_.-]+))',
        );
        for (final match in equalityPattern.allMatches(expression)) {
          final rawKey = match.group(1)!;
          final key = switch (rawKey) {
            'conversation' => 'conversation_id',
            'guideline_id' => 'guideline_document_id',
            'user' => 'user_id',
            _ => rawKey,
          };
          query[key] = match.group(2) ?? match.group(3) ?? '';
        }
      }
    }

    // Domain endpoints own their sort allowlists. Until a domain exposes one,
    // retain its server-side default instead of forwarding expression syntax.
    return query;
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
