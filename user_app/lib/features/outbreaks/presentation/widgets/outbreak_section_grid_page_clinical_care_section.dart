part of '../screens/outbreak_section_grid_page.dart';

class _ClinicalCareSection {
  const _ClinicalCareSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.documentKinds,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> documentKinds;
}

const _clinicalCareSections = <_ClinicalCareSection>[
  _ClinicalCareSection(
    title: 'Case Definition',
    subtitle: 'Who is a suspected case?',
    icon: LucideIcons.userRound,
    documentKinds: ['case_definition'],
  ),
  _ClinicalCareSection(
    title: 'Screening & Triage',
    subtitle: 'Identify and prioritise cases',
    icon: LucideIcons.listChecks,
    documentKinds: ['surveillance_protocol', 'checklist'],
  ),
  _ClinicalCareSection(
    title: 'Isolation',
    subtitle: 'Isolation and cohorting',
    icon: LucideIcons.shield,
    documentKinds: ['ipc_protocol'],
  ),
  _ClinicalCareSection(
    title: 'Clinical Management',
    subtitle: 'Treatment and supportive care',
    icon: LucideIcons.stethoscope,
    documentKinds: ['treatment_protocol', 'sop'],
  ),
  _ClinicalCareSection(
    title: 'Discharge Criteria',
    subtitle: 'When to discharge a patient',
    icon: LucideIcons.logOut,
    documentKinds: ['referral_protocol'],
  ),
  _ClinicalCareSection(
    title: 'Follow-up & Monitoring',
    subtitle: 'Post-discharge monitoring',
    icon: LucideIcons.activity,
    documentKinds: ['contact_tracing_guide'],
  ),
];

PublicOutbreakDocument? _documentForKinds(
  List<PublicOutbreakDocument> documents,
  List<String> kinds,
) {
  for (final kind in kinds) {
    for (final document in documents) {
      if (document.documentKind == kind) return document;
    }
  }
  return null;
}

String _sectionTitle(String sectionId) => switch (sectionId) {
  'clinical-care' => 'Clinical Care',
  _ => 'Outbreak guidance',
};
