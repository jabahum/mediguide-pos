import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';

part 'auth_controller.g.dart';

final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => AuthServiceSessionStore(ref.watch(authServiceProvider)),
);

typedef PrivateCacheCleaner = Future<void> Function(String userId);

final privateCacheCleanerProvider = Provider<PrivateCacheCleaner>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  return cache.clearPrivateScope;
});

@riverpod
class AuthController extends _$AuthController {
  BackendApiService get _api => ref.read(backendApiServiceProvider);

  AuthSessionStore get _store => ref.read(authSessionStoreProvider);

  @override
  Future<AuthState> build() async {
    final api = _api;
    void onSessionExpired() => unawaited(_expireSession());
    api.sessionExpired.addListener(onSessionExpired);
    ref.onDispose(() => api.sessionExpired.removeListener(onSessionExpired));
    final cachedUser = _store.currentUser;

    if (!_api.isAuthenticated) {
      if (cachedUser != null) {
        await _store.clearUser();
      }

      return const AuthState.unauthenticated();
    }

    try {
      final user = await ref.read(userRepositoryProvider).refreshProfile();

      await _store.saveUser(user);

      return AuthState.authenticated(user);
    } on BackendApiException catch (error) {
      if (error.statusCode == 401) {
        await _store.clearUser();

        return const AuthState.unauthenticated();
      }

      // Connectivity is not authentication.
      // Preserve the cached profile so the app remains
      // useful with local data while offline.
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

    if (previous?.phase == AuthPhase.authenticating) {
      return false;
    }

    state = AsyncData(AuthState.authenticating(user: previous?.user));

    try {
      final user = await _api.login(email: email, password: password);

      await _store.saveUser(user);

      state = AsyncData(AuthState.authenticated(user));

      _invalidateUserScopedProviders();

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

    if (previous?.phase == AuthPhase.authenticating) {
      return false;
    }

    state = AsyncData(AuthState.authenticating(user: previous?.user));

    try {
      final user = await _api.register(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        additionalData: additionalData,
      );

      await _store.saveUser(user);

      state = AsyncData(AuthState.authenticated(user));

      _invalidateUserScopedProviders();

      return true;
    } catch (error, stackTrace) {
      state = AsyncData(AuthState.failure(error, user: previous?.user));

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refreshProfile() async {
    final user = state.valueOrNull?.user ?? _store.currentUser;

    if (user == null) {
      return;
    }

    state = AsyncData(AuthState.refreshing(user));

    try {
      final refreshed = await ref.read(userRepositoryProvider).refreshProfile();

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

    if (user != null) {
      state = AsyncData(AuthState.refreshing(user));
    }

    try {
      await _api.logout();
    } catch (_) {
      // Local logout must still complete if the server
      // revocation request fails.
    } finally {
      await _store.clearUser();

      await _clearPrivateCache(user);

      state = const AsyncData(AuthState.unauthenticated());

      _invalidateUserScopedProviders();
    }
  }

  Future<void> _expireSession() async {
    final user = state.valueOrNull?.user ?? _store.currentUser;
    await _store.clearUser();
    await _clearPrivateCache(user);
    state = const AsyncData(AuthState.unauthenticated());
    _invalidateUserScopedProviders();
  }

  Future<void> _clearPrivateCache(User? user) async {
    if (user == null) return;
    try {
      await ref.read(privateCacheCleanerProvider)(user.id);
    } catch (_) {
      // Authentication state must still be cleared when local storage is
      // temporarily unavailable. The user scope remains inaccessible because
      // every private read requires the current authenticated user id.
    }
  }

  void _invalidateUserScopedProviders() {
    ref.invalidate(userRepositoryProvider);
    ref.invalidate(readingProgressRepositoryProvider);
    ref.invalidate(usageRepositoryProvider);
    ref.invalidate(notificationRepositoryProvider);
    ref.invalidate(supportRepositoryProvider);
    ref.invalidate(conversationRepositoryProvider);
    ref.invalidate(calculatorReviewRepositoryProvider);
  }
}
