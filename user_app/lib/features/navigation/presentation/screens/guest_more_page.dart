import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';

class GuestMorePage extends StatelessWidget {
  const GuestMorePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    body: ListView(
      padding: AppSpacing.pagePadding,
      children: [
        Text(
          'Get more from MediGuide',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        AppSpacing.gapSm,
        const Text(
          'Sign in to sync reading progress, bookmarks, notes, downloads, notifications and private support.',
        ),
        AppSpacing.gapLg,
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.login),
          icon: const Icon(LucideIcons.logIn),
          label: const Text('Sign in'),
        ),
        AppSpacing.gapSm,
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.register),
          icon: const Icon(LucideIcons.userPlus),
          label: const Text('Create account'),
        ),
        AppSpacing.gapLg,
        _MoreItem(
          icon: LucideIcons.circleHelp,
          title: 'Help and support',
          onTap: () => context.push(AppRoutes.helpCenter),
        ),
        _MoreItem(
          icon: LucideIcons.info,
          title: 'About MediGuide',
          onTap: () => context.push(AppRoutes.aboutUs),
        ),
        _MoreItem(
          icon: LucideIcons.shieldCheck,
          title: 'Terms and privacy',
          onTap: () => context.push(AppRoutes.termsAndConditions),
        ),
      ],
    ),
  );
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: AppSpacing.md,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: onTap,
    ),
  );
}
