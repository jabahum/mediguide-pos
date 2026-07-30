// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import '../enums/consultant_enums.dart';
import '../enums/user_enums.dart';
import 'base_model.dart';
import 'user.dart';

/// Consultant model based on legacy collection API consultants collection
class Consultant extends BaseModel {
  Consultant(super.data);

  /// legacy collection API collection name
  static const String collection = 'consultants';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Consultant(data));
    return true;
  })();

  /// Create Consultant from legacy collection API record
  static Consultant fromRecord(ApiRecord record) => Consultant(record.data);

  /// Create JSON for new consultant record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    required String email,
    required String phone,
    required String country,
    required ConsultantSpecialty specialty,
    required ConsultantStatus status,
    String? user,
    String? alternativePhone,
    String? licenseNumber,
    double? yearsOfExperience,
    List<ConsultantQualification>? qualifications,
    String? certifications,
    String? address,
    String? city,
    String? region,
    String? postalCode,
    String? organization,
    String? department,
    PreferredLanguage? preferredLanguage,
    String? timezone,
    Map<String, dynamic>? availability,
    List<ConsultationType>? consultationTypes,
    bool? isVerified,
    double? rating,
    double? totalConsultations,
    String? notes,
  }) {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'country': country,
      'specialty': _specialtyToDisplayValue(specialty),
      'status': status.name,
      'user': ?user,
      'alternativePhone': ?alternativePhone,
      'licenseNumber': ?licenseNumber,
      'yearsOfExperience': ?yearsOfExperience,
      if (qualifications != null)
        'qualifications': qualifications.map(_qualificationToValue).toList(),
      'certifications': ?certifications,
      'address': ?address,
      'city': ?city,
      'region': ?region,
      'postalCode': ?postalCode,
      'organization': ?organization,
      'department': ?department,
      if (preferredLanguage != null)
        'preferredLanguage': preferredLanguage.name,
      'timezone': ?timezone,
      'availability': ?availability,
      if (consultationTypes != null)
        'consultationTypes': consultationTypes
            .map(_consultationTypeToValue)
            .toList(),
      'isVerified': ?isVerified,
      'rating': ?rating,
      'totalConsultations': ?totalConsultations,
      'notes': ?notes,
    };
  }

  /// Create JSON for updating consultant record
  static Map<String, dynamic> forUpdate({
    String? name,
    String? email,
    String? phone,
    String? user,
    String? alternativePhone,
    String? licenseNumber,
    double? yearsOfExperience,
    List<ConsultantQualification>? qualifications,
    String? certifications,
    String? address,
    String? city,
    String? region,
    String? postalCode,
    String? organization,
    String? department,
    PreferredLanguage? preferredLanguage,
    String? timezone,
    Map<String, dynamic>? availability,
    List<ConsultationType>? consultationTypes,
    bool? isVerified,
    double? rating,
    double? totalConsultations,
    String? notes,
    ConsultantSpecialty? specialty,
    ConsultantStatus? status,
  }) {
    return {
      'name': ?name,
      'email': ?email,
      'phone': ?phone,
      'user': ?user,
      'alternativePhone': ?alternativePhone,
      'licenseNumber': ?licenseNumber,
      'yearsOfExperience': ?yearsOfExperience,
      if (qualifications != null)
        'qualifications': qualifications.map(_qualificationToValue).toList(),
      'certifications': ?certifications,
      'address': ?address,
      'city': ?city,
      'region': ?region,
      'postalCode': ?postalCode,
      'organization': ?organization,
      'department': ?department,
      if (preferredLanguage != null)
        'preferredLanguage': preferredLanguage.name,
      'timezone': ?timezone,
      'availability': ?availability,
      if (consultationTypes != null)
        'consultationTypes': consultationTypes
            .map(_consultationTypeToValue)
            .toList(),
      'isVerified': ?isVerified,
      'rating': ?rating,
      'totalConsultations': ?totalConsultations,
      'notes': ?notes,
      if (specialty != null) 'specialty': _specialtyToDisplayValue(specialty),
      if (status != null) 'status': status.name,
    };
  }

  // Direct string properties - late final for performance
  late final String name = get<String>("name", "");
  late final String email = get<String>("email", "");
  late final String phone = get<String>("phone", "");
  late final String alternativePhone = get<String>("alternativePhone", "");
  late final String licenseNumber = get<String>("licenseNumber", "");
  late final String certifications = get<String>("certifications", "");
  late final String address = get<String>("address", "");
  late final String city = get<String>("city", "");
  late final String region = get<String>("region", "");
  late final String country = get<String>("country", "");
  late final String postalCode = get<String>("postalCode", "");
  late final String organization = get<String>("organization", "");
  late final String department = get<String>("department", "");
  late final String timezone = get<String>("timezone", "");
  late final String notes = get<String>("notes", "");

  // Relation field
  late final String user = get<String>("user", "");

  // Numeric properties
  late final double yearsOfExperience = get<double>("yearsOfExperience", 0);
  late final double rating = get<double>("rating", 0);
  late final double totalConsultations = get<double>("totalConsultations", 0);

  // Boolean properties
  late final bool isVerified = get<bool>("isVerified", false);

  // JSON properties
  late final Map<String, dynamic> availability = get<Map<String, dynamic>>(
    "availability",
    {},
  );

  // Enum properties - use BaseModel's enhanced enum handling
  late final ConsultantSpecialty? specialty = getEnum<ConsultantSpecialty>(
    "specialty",
    ConsultantSpecialty.values,
  );
  late final ConsultantStatus status =
      getEnum<ConsultantStatus>("status", ConsultantStatus.values) ??
      ConsultantStatus.inactive;
  late final List<ConsultantQualification> qualifications =
      getEnumList<ConsultantQualification>(
        "qualifications",
        ConsultantQualification.values,
      );
  late final List<ConsultationType> consultationTypes =
      getEnumList<ConsultationType>(
        "consultationTypes",
        ConsultationType.values,
      );
  late final PreferredLanguage? preferredLanguage = getEnum<PreferredLanguage>(
    "preferredLanguage",
    PreferredLanguage.values,
  );

  // Related models - using expand functionality
  User? get userAccount => getRelation<User>("user");

  // Helper methods for enum conversion
  static String _specialtyToDisplayValue(ConsultantSpecialty specialty) {
    switch (specialty) {
      case ConsultantSpecialty.generalPractice:
        return 'General Practice';
      case ConsultantSpecialty.internalMedicine:
        return 'Internal Medicine';
      case ConsultantSpecialty.emergencyMedicine:
        return 'Emergency Medicine';
      case ConsultantSpecialty.infectiousDiseases:
        return 'Infectious Diseases';
      case ConsultantSpecialty.publicHealth:
        return 'Public Health';
      case ConsultantSpecialty.laboratoryMedicine:
        return 'Laboratory Medicine';
      default:
        // Handle other specialties with Title Case
        return _enumNameToTitleCase(specialty.name);
    }
  }

  /// Convert enum name to Title Case (e.g., 'cardiology' -> 'Cardiology')
  static String _enumNameToTitleCase(String enumName) {
    return enumName[0].toUpperCase() + enumName.substring(1);
  }

  static String _qualificationToValue(ConsultantQualification qualification) {
    switch (qualification) {
      case ConsultantQualification.md:
        return 'MD';
      case ConsultantQualification.mbbs:
        return 'MBBS';
      case ConsultantQualification.dds:
        return 'DDS';
      case ConsultantQualification.pharmD:
        return 'PharmD';
      case ConsultantQualification.rn:
        return 'RN';
      case ConsultantQualification.bsn:
        return 'BSN';
      case ConsultantQualification.msn:
        return 'MSN';
      case ConsultantQualification.dnp:
        return 'DNP';
      case ConsultantQualification.phd:
        return 'PhD';
      case ConsultantQualification.mph:
        return 'MPH';
      case ConsultantQualification.ms:
        return 'MS';
      case ConsultantQualification.ma:
        return 'MA';
      case ConsultantQualification.doDegree:
        return 'DO_DEGREE';
      default:
        return _enumNameToTitleCase(qualification.name);
    }
  }

  static String _consultationTypeToValue(ConsultationType type) {
    switch (type) {
      case ConsultationType.inPerson:
        return 'In-Person';
      case ConsultationType.telemedicine:
        return 'Telemedicine';
      case ConsultationType.phoneConsultation:
        return 'Phone Consultation';
      case ConsultationType.emergencyConsultation:
        return 'Emergency Consultation';
      case ConsultationType.secondOpinion:
        return 'Second Opinion';
      case ConsultationType.followUp:
        return 'Follow-up';
      case ConsultationType.diagnosticReview:
        return 'Diagnostic Review';
      case ConsultationType.treatmentPlanning:
        return 'Treatment Planning';
      case ConsultationType.medicationReview:
        return 'Medication Review';
      case ConsultationType.healthEducation:
        return 'Health Education';
    }
  }
}
