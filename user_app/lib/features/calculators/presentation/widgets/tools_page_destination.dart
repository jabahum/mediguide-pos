part of '../screens/tools_page.dart';

class _Destination {
  const _Destination({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    this.arguments,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Object? arguments;
}

// ============================================================================
// DESTINATION GROUP
// ============================================================================
