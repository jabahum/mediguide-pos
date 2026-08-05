/// Common status enum used across multiple collections
enum Status {
  active(label: 'Active'),
  inactive(label: 'Inactive'),
  unknown(label: 'Unknown');

  const Status({required this.label});

  final String label;
}
