// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import '../enums/ministry_directory_enums.dart';
import 'base_model.dart';
import 'district.dart';
import 'region.dart';

/// MinistryDirectory model based on backend resource API ministry_directory collection
class MinistryDirectory extends BaseModel {
  MinistryDirectory(super.data);

  /// backend resource API collection name
  static const String collection = 'ministry_directory';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => MinistryDirectory(data));
    return true;
  })();

  /// Create MinistryDirectory from backend resource API record
  static MinistryDirectory fromRecord(ApiRecord record) =>
      MinistryDirectory(record.data);

  /// Create JSON for new ministry directory record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    required String title,
    required Ministry ministry,
    required String phone,
    required String districtId,
    required MinistryDirectoryStatus status,
    String? department,
    String? alternativePhone,
    String? email,
    String? officeAddress,
    String? regionId,
    double? priorityLevel,
    String? availabilityHours,
    String? specialization,
    String? notes,
  }) {
    return {
      'name': name,
      'title': title,
      'ministry': ministry.label,
      'phone': phone,
      'district': districtId,
      'status': status.name,
      'department': ?department,
      'alternativePhone': ?alternativePhone,
      'email': ?email,
      'office_address': ?officeAddress,
      'region': ?regionId,
      'priority_level': ?priorityLevel,
      'availability_hours': ?availabilityHours,
      'specialization': ?specialization,
      'notes': ?notes,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String title = get<String>("title", "");
  late final String ministryValue = get<String>("ministry", "");
  late final String department = get<String>("department", "");
  late final String phone = get<String>("phone", "");
  late final String alternativePhone = get<String>("alternativePhone", "");
  late final String email = get<String>("email", "");
  late final String officeAddress = get<String>("office_address", "");
  late final double priorityLevel = get<double>("priority_level", 0.0);
  late final String availabilityHours = get<String>("availability_hours", "");
  late final String specialization = get<String>("specialization", "");
  late final String statusValue = get<String>("status", "");
  late final String notes = get<String>("notes", "");

  // Relationship properties
  late final District? district = getRelation<District>("district");
  late final Region? region = getRelation<Region>("region");

  // Computed properties
  Ministry get ministry {
    try {
      return Ministry.values.firstWhere((m) => m.label == ministryValue);
    } catch (e) {
      return Ministry.other;
    }
  }

  MinistryDirectoryStatus get status {
    try {
      return MinistryDirectoryStatus.values.firstWhere(
        (s) => s.name == statusValue,
      );
    } catch (e) {
      return MinistryDirectoryStatus.inactive;
    }
  }

  /// Get display name with title
  String get displayName => '$name - $title';

  /// Get formatted contact info
  String get contactInfo {
    final List<String> contacts = [phone];
    if (alternativePhone.isNotEmpty) contacts.add(alternativePhone);
    if (email.isNotEmpty) contacts.add(email);
    return contacts.join(' • ');
  }

  /// Get location string
  String get locationString {
    if (district != null && region != null) {
      return '${district!.name}, ${region!.name}';
    } else if (district != null) {
      return district!.name;
    } else if (region != null) {
      return region!.name;
    }
    return '';
  }

  /// Check if this is an emergency contact
  bool get isEmergencyContact => priorityLevel == 1.0;

  /// Check if contact is currently available (basic check - could be enhanced)
  bool get isAvailable => status == MinistryDirectoryStatus.active;
}
