part of '../screens/notifications_page.dart';

class _NotificationFilterOption {
  const _NotificationFilterOption({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

String _formatFilterLabel(String value) {
  final normalized = value.trim();

  if (normalized.isEmpty) {
    return '';
  }

  return '${normalized[0].toUpperCase()}'
      '${normalized.substring(1).toLowerCase()}';
}
