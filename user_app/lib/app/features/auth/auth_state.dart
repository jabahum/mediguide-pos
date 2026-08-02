import '../../data/models/user.dart';

enum AuthPhase {
  initializing,
  unauthenticated,
  authenticating,
  authenticated,
  refreshing,
  failure,
}

final class AuthState {
  const AuthState({required this.phase, this.user, this.error});

  const AuthState.initializing() : this(phase: AuthPhase.initializing);

  const AuthState.unauthenticated() : this(phase: AuthPhase.unauthenticated);

  const AuthState.authenticating({User? user})
    : this(phase: AuthPhase.authenticating, user: user);

  const AuthState.authenticated(User user)
    : this(phase: AuthPhase.authenticated, user: user);

  const AuthState.refreshing(User user)
    : this(phase: AuthPhase.refreshing, user: user);

  const AuthState.failure(Object error, {User? user})
    : this(phase: AuthPhase.failure, user: user, error: error);

  final AuthPhase phase;
  final User? user;
  final Object? error;

  bool get isAuthenticated =>
      user != null &&
      phase != AuthPhase.initializing &&
      phase != AuthPhase.unauthenticated;

  bool get isBusy =>
      phase == AuthPhase.initializing ||
      phase == AuthPhase.authenticating ||
      phase == AuthPhase.refreshing;
}
