import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/content/data/models/ministry_directory.dart';
import 'package:user_app/features/content/data/models/ministry_directory_enums.dart';

void main() {
  test('directory maps explicit location display fields', () {
    final entry = MinistryDirectory.fromJson({
      'id': 'entry-1',
      'name': 'Emergency desk',
      'title': 'Duty officer',
      'ministry': 'Ministry of Health',
      'phone': '+256700000000',
      'priority_level': 1,
      'status': 'active',
      'district_id': 'district-1',
      'district_name': 'Kampala',
      'region_id': 'region-1',
      'region_name': 'Central',
    });

    expect(entry.ministry, Ministry.ministryOfHealth);
    expect(entry.status, MinistryDirectoryStatus.active);
    expect(entry.locationString, 'Kampala, Central');
    expect(entry.isEmergencyContact, isTrue);
    expect(MinistryDirectory.fromJson(entry.toJson()), entry);
  });

  test('directory request omits fields not being patched', () {
    const request = MinistryDirectoryRequest(phone: '+256711111111');
    expect(request.toJson(), {'phone': '+256711111111'});
  });
}
