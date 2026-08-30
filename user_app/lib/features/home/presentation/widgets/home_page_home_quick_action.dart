part of '../screens/home_page.dart';

class _HomeQuickAction {
  const _HomeQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  final Future<void> Function() onTap;
}
