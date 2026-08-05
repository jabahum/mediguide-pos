import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/authentication/data/repositories/user_repository.dart';
import 'package:user_app/features/authentication/data/models/user_enums.dart';
import 'package:user_app/core/network/api_client.dart';

class FakeUserApi extends BackendApiService {
  String? requestedPath;
  String? requestedMethod;
  Map<String, dynamic>? requestedBody;
  Object? error;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    requestedPath = path;
    requestedMethod = method;
    requestedBody = body;
    if (error != null) {
      throw error!;
    }
    return {
      'data': {
        'id': 'user-1',
        'name': 'Updated User',
        'preferred_language': 'en',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'roles': [
          {'role_key': 'clinician'},
        ],
      },
    };
  }
}

void main() {
  test(
    'UserRepository updates profiles through the typed user endpoint',
    () async {
      final api = FakeUserApi();
      final repository = UserRepository(api);

      final result = await repository.updateProfile('user-1', {
        'preferredLanguage': 'en',
      });

      expect(api.requestedPath, '/api/v2/users/user-1');
      expect(api.requestedMethod, 'PATCH');
      expect(api.requestedBody, {'preferred_language': 'en'});
      expect(result.preferredLanguage, PreferredLanguage.english);
      expect(result.role, UserRole.healthcareProvider);
    },
  );

  test(
    'UserRepository preserves authorization errors from the transport',
    () async {
      final api = FakeUserApi()..error = StateError('forbidden');
      final repository = UserRepository(api);

      expect(
        () => repository.updateProfile('user-1', {'name': 'Blocked'}),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('UserRepository refreshes the current profile through /me', () async {
    final api = FakeUserApi();
    final repository = UserRepository(api);

    final result = await repository.refreshProfile();

    expect(api.requestedPath, '/api/v2/me');
    expect(api.requestedMethod, 'GET');
    expect(result.id, 'user-1');
  });
}
