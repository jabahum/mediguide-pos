import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_local_repository.dart';
import 'helpers/test_local_store.dart';

class FakeCalculatorApi extends BackendApiService {
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
          'id': 'calculator-1',
          'name': 'BMI',
          'type': 'calculator',
          'status': 'active',
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
  test('calculator list uses explicit typed sorting and filters', () async {
    final api = FakeCalculatorApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final result =
        await CalculatorRepository(
          api,
          CalculatorLocalRepository(store.cache),
        ).list(
          search: 'BMI',
          statuses: const ['active'],
          featured: true,
          sort: 'usage_count',
          order: 'desc',
        );

    expect(api.path, '/api/v2/calculators');
    expect(api.query?['search'], 'BMI');
    expect(api.query?['status'], 'active');
    expect(api.query?['featured'], 'true');
    expect(api.query?['sort'], 'usage_count');
    expect(api.query?['order'], 'desc');
    expect(api.query?.containsKey('filter'), isFalse);
    expect(result.items.single.id, 'calculator-1');
  });
}
