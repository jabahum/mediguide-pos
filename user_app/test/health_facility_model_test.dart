import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/facilities/data/models/health_facility.dart';

void main() {
  test('facility maps explicit relationship projections', () {
    final facility = HealthFacility.fromJson({
      'id': 'facility-1',
      'name': 'MediGuide Hospital',
      'nhpi_code': 'NHPI-1',
      'hsdt_code': 'HSDT-1',
      'facility_level_id': 'level-1',
      'facility_level_name': 'Hospital',
      'facility_level_code': 'HC-IV',
      'ownership_type_id': 'ownership-1',
      'ownership_type_name': 'Public',
      'district_id': 'district-1',
      'district_name': 'Kampala',
      'region_id': 'region-1',
      'region_name': 'Central',
      'usage_count': 4,
    });

    expect(facility.facilityLevel?.name, 'Hospital');
    expect(facility.ownershipDisplay, 'Public');
    expect(facility.fullAddress, 'Kampala, Central');
    expect(facility.usageCount, 4);
    expect(HealthFacility.fromJson(facility.toJson()), facility);
  });

  test('facility request omits fields not being updated', () {
    const request = HealthFacilityRequest(
      name: 'Updated Hospital',
      districtId: 'district-1',
    );

    expect(request.toJson(), {
      'name': 'Updated Hospital',
      'district_id': 'district-1',
    });
  });
}
