/// Route of administration enum based on legacy collection API drugs collection schema
enum RouteOfAdministration {
  oral(label: 'Oral'),
  iv(label: 'IV'),
  im(label: 'IM'),
  topical(label: 'Topical'),
  inhaled(label: 'Inhaled'),
  sublingual(label: 'Sublingual'),
  rectal(label: 'Rectal'),
  transdermal(label: 'Transdermal'),
  intranasal(label: 'Intranasal'),
  subcutaneous(label: 'Subcutaneous');

  const RouteOfAdministration({required this.label});

  final String label;
}

/// Pregnancy category enum based on legacy collection API drugs collection schema
enum PregnancyCategory {
  a(label: 'Category A'),
  b(label: 'Category B'),
  c(label: 'Category C'),
  d(label: 'Category D'),
  x(label: 'Category X'),
  unknown(label: 'Unknown');

  const PregnancyCategory({required this.label});

  final String label;
}

/// Controlled substance enum based on legacy collection API drugs collection schema
enum ControlledSubstance {
  none(label: 'None'),
  scheduleI(label: 'Schedule I'),
  scheduleII(label: 'Schedule II'),
  scheduleIII(label: 'Schedule III'),
  scheduleIV(label: 'Schedule IV'),
  scheduleV(label: 'Schedule V');

  const ControlledSubstance({required this.label});

  final String label;
}

/// Drug status enum based on legacy collection API drugs collection schema
enum DrugStatus {
  active(label: 'Active'),
  inactive(label: 'Inactive'),
  underReview(label: 'Under Review'),
  archived(label: 'Archived');

  const DrugStatus({required this.label});

  final String label;
}

/// Review status enum based on legacy collection API drugs collection schema
enum ReviewStatus {
  approved(label: 'Approved'),
  pending(label: 'Pending'),
  needsUpdate(label: 'Needs Update');

  const ReviewStatus({required this.label});

  final String label;
}
