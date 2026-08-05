import 'package:user_app/features/authentication/data/models/user_enums.dart';
import 'package:user_app/features/drugs/data/models/drug_enums.dart';
import 'package:user_app/features/consultants/data/models/consultant_enums.dart';
import 'package:user_app/shared/models/common_enums.dart';

/// Extension methods for user role enum
extension UserRoleExtension on UserRole {
  String get displayName => switch (this) {
    UserRole.superAdmin => "Super Admin",
    UserRole.admin => "Admin",
    UserRole.contentManager => "Content Manager",
    UserRole.reviewer => "Reviewer",
    UserRole.healthcareProvider => "Healthcare Provider",
    UserRole.observer => "Observer",
  };

  String get value => switch (this) {
    UserRole.superAdmin => "super_admin",
    UserRole.admin => "admin",
    UserRole.contentManager => "content_manager",
    UserRole.reviewer => "reviewer",
    UserRole.healthcareProvider => "healthcare_provider",
    UserRole.observer => "observer",
  };
}

/// Extension methods for user status enum
extension UserStatusExtension on UserStatus {
  String get displayName => switch (this) {
    UserStatus.active => "Active",
    UserStatus.inactive => "Inactive",
    UserStatus.suspended => "Suspended",
    UserStatus.pendingActivation => "Pending Activation",
  };

  String get value => switch (this) {
    UserStatus.active => "active",
    UserStatus.inactive => "inactive",
    UserStatus.suspended => "suspended",
    UserStatus.pendingActivation => "pending_activation",
  };
}

/// Extension methods for specialization enum
extension SpecializationExtension on Specialization {
  String get displayName => switch (this) {
    Specialization.generalPractice => "General Practice",
    Specialization.pediatrics => "Pediatrics",
    Specialization.internalMedicine => "Internal Medicine",
    Specialization.surgery => "Surgery",
    Specialization.emergencyMedicine => "Emergency Medicine",
    Specialization.obstetrics => "Obstetrics",
    Specialization.psychiatry => "Psychiatry",
    Specialization.radiology => "Radiology",
    Specialization.anesthesia => "Anesthesia",
    Specialization.nursing => "Nursing",
    Specialization.pharmacy => "Pharmacy",
    Specialization.laboratory => "Laboratory",
    Specialization.publicHealth => "Public Health",
    Specialization.other => "Other",
  };

  String get value => displayName;
}

/// Extension methods for preferred language enum
extension PreferredLanguageExtension on PreferredLanguage {
  String get displayName => switch (this) {
    PreferredLanguage.english => "English",
    PreferredLanguage.french => "French",
    PreferredLanguage.spanish => "Spanish",
    PreferredLanguage.portuguese => "Portuguese",
    PreferredLanguage.arabic => "Arabic",
    PreferredLanguage.swahili => "Swahili",
    PreferredLanguage.amharic => "Amharic",
  };

  String get value => displayName;
}

/// Extension methods for route of administration enum
extension RouteOfAdministrationExtension on RouteOfAdministration {
  String get displayName => switch (this) {
    RouteOfAdministration.oral => "Oral",
    RouteOfAdministration.iv => "IV",
    RouteOfAdministration.im => "IM",
    RouteOfAdministration.topical => "Topical",
    RouteOfAdministration.inhaled => "Inhaled",
    RouteOfAdministration.sublingual => "Sublingual",
    RouteOfAdministration.rectal => "Rectal",
    RouteOfAdministration.transdermal => "Transdermal",
    RouteOfAdministration.intranasal => "Intranasal",
    RouteOfAdministration.subcutaneous => "Subcutaneous",
  };

  String get value => name;
}

/// Extension methods for pregnancy category enum
extension PregnancyCategoryExtension on PregnancyCategory {
  String get displayName => switch (this) {
    PregnancyCategory.a => "A",
    PregnancyCategory.b => "B",
    PregnancyCategory.c => "C",
    PregnancyCategory.d => "D",
    PregnancyCategory.x => "X",
    PregnancyCategory.unknown => "Unknown",
  };

  String get value => displayName;
}

/// Extension methods for controlled substance enum
extension ControlledSubstanceExtension on ControlledSubstance {
  String get displayName => switch (this) {
    ControlledSubstance.none => "None",
    ControlledSubstance.scheduleI => "Schedule I",
    ControlledSubstance.scheduleII => "Schedule II",
    ControlledSubstance.scheduleIII => "Schedule III",
    ControlledSubstance.scheduleIV => "Schedule IV",
    ControlledSubstance.scheduleV => "Schedule V",
  };

  String get value => displayName;
}

/// Extension methods for drug status enum
extension DrugStatusExtension on DrugStatus {
  String get displayName => switch (this) {
    DrugStatus.active => "Active",
    DrugStatus.inactive => "Inactive",
    DrugStatus.underReview => "Under Review",
    DrugStatus.archived => "Archived",
  };

  String get value => switch (this) {
    DrugStatus.active => "active",
    DrugStatus.inactive => "inactive",
    DrugStatus.underReview => "under_review",
    DrugStatus.archived => "archived",
  };
}

/// Extension methods for review status enum
extension ReviewStatusExtension on ReviewStatus {
  String get displayName => switch (this) {
    ReviewStatus.approved => "Approved",
    ReviewStatus.pending => "Pending",
    ReviewStatus.needsUpdate => "Needs Update",
  };

  String get value => switch (this) {
    ReviewStatus.approved => "approved",
    ReviewStatus.pending => "pending",
    ReviewStatus.needsUpdate => "needs_update",
  };
}

/// Extension methods for common status enum
extension StatusExtension on Status {
  String get displayName => switch (this) {
    Status.active => "Active",
    Status.inactive => "Inactive",
  };

  String get value => name;
}

/// Extension methods for consultant specialty enum
extension ConsultantSpecialtyExtension on ConsultantSpecialty {
  String get displayName => switch (this) {
    ConsultantSpecialty.generalPractice => "General Practice",
    ConsultantSpecialty.internalMedicine => "Internal Medicine",
    ConsultantSpecialty.pediatrics => "Pediatrics",
    ConsultantSpecialty.surgery => "Surgery",
    ConsultantSpecialty.cardiology => "Cardiology",
    ConsultantSpecialty.neurology => "Neurology",
    ConsultantSpecialty.psychiatry => "Psychiatry",
    ConsultantSpecialty.orthopedics => "Orthopedics",
    ConsultantSpecialty.dermatology => "Dermatology",
    ConsultantSpecialty.ophthalmology => "Ophthalmology",
    ConsultantSpecialty.emergencyMedicine => "Emergency Medicine",
    ConsultantSpecialty.radiology => "Radiology",
    ConsultantSpecialty.anesthesiology => "Anesthesiology",
    ConsultantSpecialty.pathology => "Pathology",
    ConsultantSpecialty.oncology => "Oncology",
    ConsultantSpecialty.endocrinology => "Endocrinology",
    ConsultantSpecialty.gastroenterology => "Gastroenterology",
    ConsultantSpecialty.pulmonology => "Pulmonology",
    ConsultantSpecialty.nephrology => "Nephrology",
    ConsultantSpecialty.infectiousDiseases => "Infectious Diseases",
    ConsultantSpecialty.rheumatology => "Rheumatology",
    ConsultantSpecialty.publicHealth => "Public Health",
    ConsultantSpecialty.nursing => "Nursing",
    ConsultantSpecialty.pharmacy => "Pharmacy",
    ConsultantSpecialty.laboratoryMedicine => "Laboratory Medicine",
    ConsultantSpecialty.other => "Other",
  };

  String get value => displayName;
}

/// Extension methods for consultant status enum
extension ConsultantStatusExtension on ConsultantStatus {
  String get displayName => switch (this) {
    ConsultantStatus.active => "Active",
    ConsultantStatus.inactive => "Inactive",
    ConsultantStatus.pendingApproval => "Pending Approval",
    ConsultantStatus.suspended => "Suspended",
  };

  String get value => name;
}
