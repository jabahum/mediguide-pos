import '../../data/models/user.dart';
import '../../data/services/auth_service.dart';

abstract interface class AuthSessionStore {
  User? get currentUser;

  Future<bool> saveUser(User user);

  Future<bool> clearUser();
}

final class AuthServiceSessionStore implements AuthSessionStore {
  AuthServiceSessionStore(this._service);

  final AuthService _service;

  @override
  User? get currentUser => _service.currentUser.value;

  @override
  Future<bool> saveUser(User user) => _service.saveUser(user);

  @override
  Future<bool> clearUser() => _service.clearUser();
}
