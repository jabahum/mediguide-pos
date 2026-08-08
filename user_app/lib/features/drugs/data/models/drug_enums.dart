/// Route of administration values exposed by the typed drugs API.
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

/// Pregnancy category values exposed by the typed drugs API.
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

/// Controlled-substance values exposed by the typed drugs API.
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

/// Drug status values exposed by the typed drugs API.
enum DrugStatus {
  active(label: 'Active'),
  inactive(label: 'Inactive'),
  underReview(label: 'Under Review'),
  archived(label: 'Archived');

  const DrugStatus({required this.label});

  final String label;
}

/// Review status values exposed by the typed drugs API.
enum ReviewStatus {
  approved(label: 'Approved'),
  pending(label: 'Pending'),
  needsUpdate(label: 'Needs Update');

  const ReviewStatus({required this.label});

  final String label;
}
