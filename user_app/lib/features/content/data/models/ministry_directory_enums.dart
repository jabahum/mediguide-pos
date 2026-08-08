/// Ministry-directory values exposed by the typed content API.
enum Ministry {
  ministryOfHealth(label: 'Ministry of Health'),
  ministryOfEducation(label: 'Ministry of Education'),
  ministryOfLocalGovernment(label: 'Ministry of Local Government'),
  ministryOfAgriculture(label: 'Ministry of Agriculture'),
  ministryOfWaterAndEnvironment(label: 'Ministry of Water and Environment'),
  ministryOfInternalAffairs(label: 'Ministry of Internal Affairs'),
  ministryOfGenderLabourAndSocialDevelopment(
    label: 'Ministry of Gender, Labour and Social Development',
  ),
  ministryOfFinance(label: 'Ministry of Finance'),
  ministryOfTrade(label: 'Ministry of Trade'),
  ministryOfTransport(label: 'Ministry of Transport'),
  other(label: 'Other');

  const Ministry({required this.label});

  final String label;
}

/// Ministry directory status enum
enum MinistryDirectoryStatus {
  active(label: 'Active'),
  inactive(label: 'Inactive'),
  pending(label: 'Pending');

  const MinistryDirectoryStatus({required this.label});

  final String label;
}
