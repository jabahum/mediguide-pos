import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/data/models/user.dart';

final class UserRepository {
  UserRepository(this._api);

  final BackendApiService _api;

  Future<User> updateProfile(String userId, Map<String, dynamic> fields) async {
    final response = await _api.requestJson(
      '/api/v2/users/$userId',
      method: 'PATCH',
      body: _normalizeOutgoing(fields),
    );
    return User.fromJson(_data(response));
  }

  Future<User> refreshProfile() async {
    final response = await _api.requestJson('/api/v2/me', method: 'GET');
    return User.fromJson(_data(response));
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

  Future<Map<String, dynamic>> requestEmailVerification(String email) async {
    final response = await _api.requestJson(
      '/api/v2/auth/email-verification/request',
      method: 'POST',
      body: {'email': email},
      includeAuth: false,
    );
    return _data(response);
  }

  Future<void> confirmEmailVerification(String token) async {
    await _api.requestJson(
      '/api/v2/auth/email-verification/confirm',
      method: 'POST',
      body: {'token': token},
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

  String _snakeCase(String value) => value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}',
  );
}
