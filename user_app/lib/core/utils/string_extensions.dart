/// Extension to convert camelCase strings to Title Case
extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;

    // Handle enum string format (e.g., 'ConsultantSpecialty.generalPractice')
    String text = this;
    if (contains('.')) {
      text = split('.').last;
    }

    // Convert camelCase to Title Case
    return text
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
