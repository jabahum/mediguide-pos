/// User role enum based on legacy collection API users collection schema
enum UserRole {
  superAdmin(label: 'Super Admin'),
  admin(label: 'Admin'),
  contentManager(label: 'Content Manager'),
  reviewer(label: 'Reviewer'),
  healthcareProvider(label: 'Healthcare Provider'),
  observer(label: 'Observer');

  const UserRole({required this.label});

  final String label;
}

/// User status enum based on legacy collection API users collection schema
enum UserStatus {
  active(label: 'Active'),
  inactive(label: 'Inactive'),
  suspended(label: 'Suspended'),
  pendingActivation(label: 'Pending Activation');

  const UserStatus({required this.label});

  final String label;
}

/// User specialization enum based on legacy collection API users collection schema
enum Specialization {
  generalPractice(label: 'General Practice'),
  pediatrics(label: 'Pediatrics'),
  internalMedicine(label: 'Internal Medicine'),
  surgery(label: 'Surgery'),
  emergencyMedicine(label: 'Emergency Medicine'),
  obstetrics(label: 'Obstetrics & Gynecology'),
  psychiatry(label: 'Psychiatry'),
  radiology(label: 'Radiology'),
  anesthesia(label: 'Anesthesia'),
  nursing(label: 'Nursing'),
  pharmacy(label: 'Pharmacy'),
  laboratory(label: 'Laboratory'),
  publicHealth(label: 'Public Health'),
  other(label: 'Other');

  const Specialization({required this.label});

  final String label;
}

/// Preferred language enum based on legacy collection API users collection schema
enum PreferredLanguage {
  english(label: 'English'),
  french(label: 'French'),
  spanish(label: 'Spanish'),
  portuguese(label: 'Portuguese'),
  arabic(label: 'Arabic'),
  swahili(label: 'Swahili'),
  amharic(label: 'Amharic');

  const PreferredLanguage({required this.label});

  final String label;
}
