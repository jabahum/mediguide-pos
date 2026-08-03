import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/data/repositories/consultant_repository.dart';
import 'package:user_app/app/data/repositories/facility_repository.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/modules/consultants_module/consultants_controller.dart';
import 'package:user_app/app/modules/health_infrastructure_module/health_infrastructure_controller.dart';

final class DirectoryApi extends BackendApiService {
  String? lastPath;
  Map<String, String>? lastQuery;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    lastPath = path;
    lastQuery = query;
    if (method == 'POST') return {'data': {}};
    if (path == '/api/v2/consultants') {
      return {
        'data': {
          'items': [
            {
              'id': 'consultant-1',
              'name': 'Dr Amina',
              'specialty': 'cardiology',
              'city': 'Kampala',
              'status': 'active',
            },
          ],
        },
      };
    }
    if (path == '/api/v2/regions') {
      return {
        'data': {
          'items': [
            {'id': 'region-1', 'name': 'Central'},
          ],
        },
      };
    }
    if (path == '/api/v2/facility-levels') {
      return {
        'data': {
          'items': [
            {'id': 'level-1', 'name': 'Hospital'},
          ],
        },
      };
    }
    if (path == '/api/v2/ownership-types') {
      return {
        'data': {
          'items': [
            {'id': 'owner-1', 'name': 'Public'},
          ],
        },
      };
    }
    if (path == '/api/v2/districts') {
      return {
        'data': {
          'items': [
            {'id': 'district-1', 'name': 'Kampala'},
          ],
        },
      };
    }
    if (path == '/api/v2/facilities') {
      return {
        'data': {
          'items': [
            {'id': 'facility-1', 'name': 'City Hospital'},
          ],
        },
      };
    }
    throw StateError('Unexpected request: $method $path');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('facility catalogue restores typed tree filters', () async {
    final controller = HealthInfrastructureController(
      FacilityRepository(DirectoryApi()),
      const {
        'treeFilters': {'region': 'region-1', 'district': 'district-1'},
      },
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(controller.treeFilters['region'], 'region-1');
    expect(controller.hasActiveFilters, isTrue);
    expect(controller.availableRegions.single.name, 'Central');
  });

  test('consultant catalogue restores region and specialty filters', () async {
    final controller = ConsultantsController(
      ConsultantRepository(DirectoryApi()),
      const {
        'treeFilters': {
          'region': 'Central',
          'city': 'Kampala',
          'specialty': 'cardiology',
        },
      },
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(controller.selectedRegion, 'Central');
    expect(controller.selectedCity, 'Kampala');
    expect(controller.selectedSpecialty, 'cardiology');
    expect(controller.hasActiveFilters, isTrue);
    expect(controller.availableLocations, contains('Kampala'));
  });

  test('facility list and usage use dedicated typed endpoints', () async {
    final api = DirectoryApi();
    final repository = FacilityRepository(api);
    await repository.listFacilities(
      page: 1,
      perPage: 20,
      regionId: 'region-1',
      districtId: 'district-1',
    );
    expect(api.lastPath, '/api/v2/facilities');
    expect(api.lastQuery?['region_id'], 'region-1');
    expect(api.lastQuery?['district_id'], 'district-1');
    expect(api.lastQuery?.containsKey('filter'), isFalse);

    await repository.recordUsage('facility-1');
    expect(api.lastPath, '/api/v2/facilities/facility-1/usage');
  });

  test('consultant usage uses its dedicated endpoint', () async {
    final api = DirectoryApi();
    await ConsultantRepository(api).recordUsage('consultant-1');
    expect(api.lastPath, '/api/v2/consultants/consultant-1/usage');
  });
}
