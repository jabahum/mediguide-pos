import '../models/api_record.dart';
import '../services/backend_api_service.dart';

final class UserRepository {
  UserRepository(this._api);

  final BackendApiService _api;

  Future<ApiRecord> updateProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    final response = await _api.requestJson(
      '/api/v2/users/$userId',
      method: 'PATCH',
      body: _normalizeOutgoing(fields),
    );
    return ApiRecord(_normalizeUser(_data(response)));
  }

  Future<ApiRecord> refreshProfile() async {
    final response = await _api.requestJson('/api/v2/me', method: 'GET');
    return ApiRecord(_normalizeUser(_data(response)));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _api.requestJson(
      '/api/v2/me/password',
      method: 'POST',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await _api.requestJson(
      '/api/v2/auth/password-reset/request',
      method: 'POST',
      body: {'email': email},
      includeAuth: false,
    );
    return _data(response);
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    await _api.requestJson(
      '/api/v2/auth/password-reset/confirm',
      method: 'POST',
      body: {
        'token': token,
        'password': password,
        'password_confirm': passwordConfirm,
      },
      includeAuth: false,
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  Map<String, dynamic> _normalizeOutgoing(Map<String, dynamic> fields) {
    return fields.map((key, value) => MapEntry(_snakeCase(key), value));
  }

  Map<String, dynamic> _normalizeUser(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{...raw};
    for (final entry in raw.entries) {
      if (entry.key.contains('_')) {
        normalized[_camelCase(entry.key)] = entry.value;
      }
    }
    final roles = raw['roles'];
    if (raw['role'] == null && roles is List && roles.isNotEmpty) {
      final first = roles.first;
      if (first is Map) {
        normalized['role'] = first['role_key'] ?? first['name'] ?? '';
      }
    }
    normalized['collectionName'] = 'users';
    normalized['collectionId'] = 'users';
    normalized['created'] = raw['created_at']?.toString() ?? '';
    normalized['updated'] = raw['updated_at']?.toString() ?? '';
    return normalized;
  }

  String _snakeCase(String value) => value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}',
  );

  String _camelCase(String value) {
    final parts = value.split('_');
    return parts.first +
        parts.skip(1).map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1);
        }).join();
  }
}
