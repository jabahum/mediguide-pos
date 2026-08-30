part of '../screens/help_center_page.dart';

class _TicketStatusFilter {
  const _TicketStatusFilter({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

// ===========================================================================
// HELPERS
// ===========================================================================

String _statusLabel(String value) {
  return switch (value) {
    'open' => 'Open',
    'inProgress' => 'In Progress',
    'resolved' => 'Resolved',
    'closed' => 'Closed',
    _ => 'All',
  };
}
