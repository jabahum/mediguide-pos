import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/facilities/data/models/facility_reference.dart';

void main() {
  test('district maps explicit hierarchy fields and ignores extras', () {
    final district = District.fromJson({
      'id': 'district-1',
      'name': 'Kampala',
      'region_id': 'region-1',
      'region_name': 'Central',
      'health_sub_region_id': 'hsr-1',
      'health_sub_region_name': 'Kampala Metropolitan',
      'created_at': '2026-08-05T08:00:00Z',
      'future_field': 'ignored',
    });

    expect(district.regionId, 'region-1');
    expect(district.healthSubRegionName, 'Kampala Metropolitan');
    expect(district.createdAt, DateTime.utc(2026, 8, 5, 8));
    expect(District.fromJson(district.toJson()), district);
  });

  test('subcounty and authority retain parent display data', () {
    const subcounty = Subcounty(
      id: 'subcounty-1',
      name: 'Central Division',
      countyId: 'county-1',
      countyName: 'Kampala',
      districtId: 'district-1',
      districtName: 'Kampala',
    );
    const authority = Authority(
      id: 'authority-1',
      name: 'City Authority',
      ownershipTypeId: 'ownership-1',
      ownershipTypeName: 'Public',
    );

    expect(subcounty.copyWith(name: 'Nakawa').name, 'Nakawa');
    expect(authority.toJson()['ownership_type_id'], 'ownership-1');
    expect(Authority.fromJson(authority.toJson()), authority);
  });

  test('facility reference PATCH payload omits absent values', () {
    const request = FacilityReferenceRequest(
      name: 'New district name',
      regionId: 'region-1',
    );

    expect(request.toJson(), {
      'name': 'New district name',
      'region_id': 'region-1',
    });
  });
}
