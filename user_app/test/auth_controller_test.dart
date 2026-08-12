import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';
import 'package:user_app/app/providers/app_providers.dart';

final class FakeAuthSessionStore implements AuthSessionStore {
  FakeAuthSessionStore([this.currentUser]);
  @override
  User? currentUser;
  int clearCalls = 0;
  int saveCalls = 0;

  @override
  Future<bool> clearUser() async {
    clearCalls++;
    currentUser = null;
    return true;
  }

  @override
  Future<bool> saveUser(User user) async {
    saveCalls++;
    currentUser = user;
    return true;
  }
}

final class FakeBackendApiService extends BackendApiService {
  FakeBackendApiService({this.authenticated = false});
  bool authenticated;
  int loginCalls = 0;
  int logoutCalls = 0;
  Completer<User>? pendingLogin;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Future<User> login({
    required String email,
    required String password,
    String? expand,
  }) async {
    loginCalls++;
    final pending = pendingLogin;
    if (pending != null) return pending.future;
    authenticated = true;
    return User(id: 'user-1', name: 'Clinician', email: email);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    authenticated = false;
  }

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async => {
    'data': {
      'id': 'user-1',
      'name': 'Refreshed Clinician',
      'email': 'clinician@example.com',
    },
  };
}

ProviderContainer createContainer(
  FakeBackendApiService api,
  FakeAuthSessionStore store,
) {
  final container = ProviderContainer(
    overrides: [
      backendApiServiceProvider.overrideWithValue(api),
      authSessionStoreProvider.overrideWithValue(store),
      privateCacheCleanerProvider.overrideWithValue((_) async {}),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('restores and refreshes a persisted authenticated session', () async {
    final api = FakeBackendApiService(authenticated: true);
    final store = FakeAuthSessionStore(
      const User(id: 'user-1', name: 'Cached Clinician'),
    );
    final container = createContainer(api, store);

    final result = await container.read(authControllerProvider.future);

    expect(result.phase, AuthPhase.authenticated);
    expect(result.user?.name, 'Refreshed Clinician');
    expect(store.saveCalls, 1);
  });

  test('removes stale profile data when no token exists', () async {
    final api = FakeBackendApiService();
    final store = FakeAuthSessionStore(const User(id: 'stale-user'));
    final container = createContainer(api, store);

    final result = await container.read(authControllerProvider.future);

    expect(result.phase, AuthPhase.unauthenticated);
    expect(store.currentUser, isNull);
    expect(store.clearCalls, 1);
  });

  test('login persists user and rejects a duplicate submission', () async {
    final api = FakeBackendApiService()..pendingLogin = Completer<User>();
    final store = FakeAuthSessionStore();
    final container = createContainer(api, store);
    await container.read(authControllerProvider.future);

    final controller = container.read(authControllerProvider.notifier);
    final first = controller.login(email: 'c@example.com', password: 'secret');
    final duplicate = await controller.login(
      email: 'c@example.com',
      password: 'secret',
    );
    expect(duplicate, isFalse);
    expect(api.loginCalls, 1);

    api.pendingLogin!.complete(const User(id: 'user-1', name: 'Clinician'));
    expect(await first, isTrue);
    expect(store.currentUser?.id, 'user-1');
    expect(
      container.read(authControllerProvider).value?.phase,
      AuthPhase.authenticated,
    );
  });

  test('logout clears the session and exposes unauthenticated state', () async {
    final api = FakeBackendApiService(authenticated: true);
    final store = FakeAuthSessionStore(const User(id: 'user-1'));
    final container = createContainer(api, store);
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).logout();

    expect(api.logoutCalls, 1);
    expect(store.currentUser, isNull);
    expect(
      container.read(authControllerProvider).value?.phase,
      AuthPhase.unauthenticated,
    );
  });
}
