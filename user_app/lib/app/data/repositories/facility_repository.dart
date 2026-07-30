import '../models/models.dart';
import '../services/backend_api_service.dart';

final class FacilityRepository {
  FacilityRepository(this._api);

  final BackendApiService _api;

  Future<PagedResult<ApiRecord>> listFacilities({
    required int page,
    required int perPage,
    String? search,
    String? regionId,
    String? districtId,
    String? facilityLevelId,
    String? ownershipTypeId,
  }) {
    return _api.getFacilities(
      page: page,
      perPage: perPage,
      search: search,
      regionId: regionId,
      districtId: districtId,
      facilityLevelId: facilityLevelId,
      ownershipTypeId: ownershipTypeId,
    );
  }

  Future<PagedResult<ApiRecord>> regions() => _api.getFacilityReference(
    path: '/api/v2/regions',
    collectionName: Region.collection,
  );

  Future<PagedResult<ApiRecord>> districts({String? regionId}) =>
      _api.getFacilityReference(
        path: '/api/v2/districts',
        collectionName: District.collection,
        regionId: regionId,
      );

  Future<PagedResult<ApiRecord>> levels() => _api.getFacilityReference(
    path: '/api/v2/facility-levels',
    collectionName: FacilityLevel.collection,
  );

  Future<PagedResult<ApiRecord>> ownershipTypes() => _api.getFacilityReference(
    path: '/api/v2/ownership-types',
    collectionName: OwnershipType.collection,
  );
}
