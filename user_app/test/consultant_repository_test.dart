import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_local_repository.dart';
import 'helpers/test_local_store.dart';

class FakeConsultantApi extends BackendApiService {
  String? path;
  Map<String, String>? query;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    this.path = path;
    this.query = query;
    return {
      'items': [
        {
          'id': 'consultant-1',
          'name': 'Dr Amina',
          'email': 'amina@example.com',
          'phone': '+256700000000',
          'specialty': 'Cardiology',
          'country': 'Uganda',
          'status': 'active',
          'is_verified': true,
          'consultation_types': ['Telemedicine'],
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      ],
      'page': 1,
      'per_page': 20,
      'total_items': 1,
      'total_pages': 1,
    };
  }
}

void main() {
  test(
    'consultant list sends typed query parameters and normalizes fields',
    () async {
      final api = FakeConsultantApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final result = await ConsultantRepository(
        api,
        ConsultantLocalRepository(store.cache),
      ).list(search: 'amina', specialty: 'Cardiology', verified: true);
      expect(api.path, '/api/v2/consultants');
      expect(api.query?['search'], 'amina');
      expect(api.query?['specialty'], 'Cardiology');
      expect(api.query?['verified'], 'true');
      expect(api.query?.containsKey('filter'), isFalse);
      expect(result.items.single.isVerified, true);
    },
  );
}
