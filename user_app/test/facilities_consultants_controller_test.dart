import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_repository.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_local_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_local_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/consultants/presentation/controllers/consultants_controller.dart';
import 'package:user_app/features/facilities/presentation/controllers/health_infrastructure_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'helpers/test_local_store.dart';

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

  test('facility catalogue restores typed tree filters', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = FacilityRepository(
      DirectoryApi(),
      FacilityLocalRepository(store.cache),
    );
    const arguments = {
      'treeFilters': {'region': 'region-1', 'district': 'district-1'},
    };
    final provider = healthInfrastructureControllerProvider(arguments);
    final container = ProviderContainer(
      overrides: [facilityRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    await container.read(provider.notifier).reloadFilterOptions();
    final state = container.read(provider);

    expect(state.treeFilters['region'], 'region-1');
    expect(state.hasActiveFilters, isTrue);
    expect(state.availableRegions.single.name, 'Central');
  });

  test('consultant catalogue restores region and specialty filters', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = ConsultantRepository(
      DirectoryApi(),
      ConsultantLocalRepository(store.cache),
    );
    const arguments = {
      'treeFilters': {
        'region': 'Central',
        'city': 'Kampala',
        'specialty': 'cardiology',
      },
    };
    final provider = consultantsControllerProvider(arguments);
    final container = ProviderContainer(
      overrides: [consultantRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    await container.read(provider.notifier).reloadFilterOptions();
    final state = container.read(provider);

    expect(state.selectedRegion, 'Central');
    expect(state.selectedCity, 'Kampala');
    expect(state.selectedSpecialty, 'cardiology');
    expect(state.hasActiveFilters, isTrue);
    expect(state.availableLocations, contains('Kampala'));
  });

  test('facility list and usage use dedicated typed endpoints', () async {
    final api = DirectoryApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = FacilityRepository(
      api,
      FacilityLocalRepository(store.cache),
    );
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
    final store = TestLocalStore();
    addTearDown(store.close);
    await ConsultantRepository(
      api,
      ConsultantLocalRepository(store.cache),
    ).recordUsage('consultant-1');
    expect(api.lastPath, '/api/v2/consultants/consultant-1/usage');
  });
}
