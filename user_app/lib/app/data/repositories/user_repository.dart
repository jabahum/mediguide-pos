import '../models/api_record.dart';
import '../services/backend_api_service.dart';

final class UserRepository {
  UserRepository(this._api);

  final BackendApiService _api;

  Future<ApiRecord> updateProfile(String userId, Map<String, dynamic> fields) {
    return _api.updateCurrentUser(userId, fields);
  }
}
