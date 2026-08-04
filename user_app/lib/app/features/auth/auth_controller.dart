import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/services/backend_api_service.dart';
import '../../core/di/core_providers.dart';
import 'auth_session_store.dart';
import 'auth_state.dart';

final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => AuthServiceSessionStore(ref.watch(authServiceProvider)),
);

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  BackendApiService get _api => ref.read(backendApiServiceProvider);
  AuthSessionStore get _store => ref.read(authSessionStoreProvider);

  @override
  Future<AuthState> build() async {
    final cachedUser = _store.currentUser;
    if (!_api.isAuthenticated) {
      if (cachedUser != null) {
        await _store.clearUser();
      }
      return const AuthState.unauthenticated();
    }

    try {
      final record = await ref.read(userRepositoryProvider).refreshProfile();
      final user = User.fromRecord(record);
      await _store.saveUser(user);
      return AuthState.authenticated(user);
    } on BackendApiException catch (error) {
      if (error.statusCode == 401) {
        await _store.clearUser();
        return const AuthState.unauthenticated();
      }

      // Connectivity is not authentication. Preserve an already restored
      // profile so the app remains useful with its local data while offline.
      if (cachedUser != null) {
        return AuthState.authenticated(cachedUser);
      }
      return AuthState.failure(error);
    } catch (error) {
      if (cachedUser != null) {
        return AuthState.authenticated(cachedUser);
      }
      return AuthState.failure(error);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    final previous = state.valueOrNull;
    if (previous?.phase == AuthPhase.authenticating) return false;

    state = AsyncData(AuthState.authenticating(user: previous?.user));
    try {
      final record = await _api.login(email: email, password: password);
      final user = User.fromRecord(record);
      await _store.saveUser(user);
      state = AsyncData(AuthState.authenticated(user));
      return true;
    } catch (error, stackTrace) {
      state = AsyncData(AuthState.failure(error, user: previous?.user));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String passwordConfirm,
    Map<String, dynamic>? additionalData,
  }) async {
    final previous = state.valueOrNull;
    if (previous?.phase == AuthPhase.authenticating) return false;

    state = AsyncData(AuthState.authenticating(user: previous?.user));
    try {
      final record = await _api.register(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        additionalData: additionalData,
      );
      final user = User.fromRecord(record);
      await _store.saveUser(user);
      state = AsyncData(AuthState.authenticated(user));
      return true;
    } catch (error, stackTrace) {
      state = AsyncData(AuthState.failure(error, user: previous?.user));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refreshProfile() async {
    final user = state.valueOrNull?.user ?? _store.currentUser;
    if (user == null) return;

    state = AsyncData(AuthState.refreshing(user));
    try {
      final record = await ref.read(userRepositoryProvider).refreshProfile();
      final refreshed = User.fromRecord(record);
      await _store.saveUser(refreshed);
      state = AsyncData(AuthState.authenticated(refreshed));
    } catch (error) {
      state = AsyncData(AuthState.failure(error, user: user));
    }
  }

  Future<void> replaceUser(User user) async {
    await _store.saveUser(user);
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> logout() async {
    final user = state.valueOrNull?.user ?? _store.currentUser;
    if (user != null) state = AsyncData(AuthState.refreshing(user));
    try {
      await _api.logout();
    } catch (_) {
      // Local logout must still complete when the revocation request cannot
      // reach the server. The transport clears its local tokens in `finally`.
    } finally {
      await _store.clearUser();
      state = const AsyncData(AuthState.unauthenticated());
      _invalidateUserScopedProviders();
    }
  }

  void _invalidateUserScopedProviders() {
    ref.invalidate(userRepositoryProvider);
    ref.invalidate(readingProgressRepositoryProvider);
    ref.invalidate(usageRepositoryProvider);
    ref.invalidate(notificationRepositoryProvider);
    ref.invalidate(supportRepositoryProvider);
    ref.invalidate(conversationRepositoryProvider);
  }
}
