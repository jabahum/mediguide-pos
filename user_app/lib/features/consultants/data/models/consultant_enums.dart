/// Consultant specialties exposed by the typed consultant API.
enum ConsultantSpecialty {
  generalPractice(label: 'General Practice'),
  internalMedicine(label: 'Internal Medicine'),
  pediatrics(label: 'Pediatrics'),
  surgery(label: 'Surgery'),
  cardiology(label: 'Cardiology'),
  neurology(label: 'Neurology'),
  psychiatry(label: 'Psychiatry'),
  orthopedics(label: 'Orthopedics'),
  dermatology(label: 'Dermatology'),
  ophthalmology(label: 'Ophthalmology'),
  emergencyMedicine(label: 'Emergency Medicine'),
  radiology(label: 'Radiology'),
  anesthesiology(label: 'Anesthesiology'),
  pathology(label: 'Pathology'),
  oncology(label: 'Oncology'),
  endocrinology(label: 'Endocrinology'),
  gastroenterology(label: 'Gastroenterology'),
  pulmonology(label: 'Pulmonology'),
  nephrology(label: 'Nephrology'),
  infectiousDiseases(label: 'Infectious Diseases'),
  rheumatology(label: 'Rheumatology'),
  publicHealth(label: 'Public Health'),
  nursing(label: 'Nursing'),
  pharmacy(label: 'Pharmacy'),
  laboratoryMedicine(label: 'Laboratory Medicine'),
  other(label: 'Other');

  const ConsultantSpecialty({required this.label});

  final String label;
}

/// Consultant qualifications exposed by the typed consultant API.
enum ConsultantQualification {
  md(label: 'MD'),
  mbbs(label: 'MBBS'),
  dds(label: 'DDS'),
  pharmD(label: 'PharmD'),
  rn(label: 'RN'),
  bsn(label: 'BSN'),
  msn(label: 'MSN'),
  dnp(label: 'DNP'),
  phd(label: 'PhD'),
  mph(label: 'MPH'),
  ms(label: 'MS'),
  ma(label: 'MA'),
  diploma(label: 'Diploma'),
  certificate(label: 'Certificate'),
  fellowship(label: 'Fellowship'),
  residency(label: 'Residency'),
  other(label: 'Other'),
  doDegree(label: 'DO Degree');

  const ConsultantQualification({required this.label});

  final String label;
}

/// Consultation types exposed by the typed consultant API.
enum ConsultationType {
  inPerson(label: 'In-Person'),
  telemedicine(label: 'Telemedicine'),
  phoneConsultation(label: 'Phone Consultation'),
  emergencyConsultation(label: 'Emergency Consultation'),
  secondOpinion(label: 'Second Opinion'),
  followUp(label: 'Follow-Up'),
  diagnosticReview(label: 'Diagnostic Review'),
  treatmentPlanning(label: 'Treatment Planning'),
  medicationReview(label: 'Medication Review'),
  healthEducation(label: 'Health Education');

  const ConsultationType({required this.label});

  final String label;
}

/// Consultant statuses exposed by the typed consultant API.
enum ConsultantStatus {
  active(label: 'Active'),
  inactive(label: 'Inactive'),
  pendingApproval(label: 'Pending Approval'),
  suspended(label: 'Suspended');

  const ConsultantStatus({required this.label});

  final String label;
}
