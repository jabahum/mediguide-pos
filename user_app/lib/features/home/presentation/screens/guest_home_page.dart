import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';

class GuestHomePage extends StatelessWidget {
  const GuestHomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('MediGuide'),
      actions: [
        TextButton(
          onPressed: () => context.push(AppRoutes.login),
          child: const Text('Sign in'),
        ),
      ],
    ),
    body: ListView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: AppSpacing.md,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Clinical guidance, wherever care happens',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        AppSpacing.gapSm,
        const Text(
          'Browse reviewed public guidelines. Sign in for bookmarks, notes, downloads, progress and private services.',
        ),
        AppSpacing.gapLg,
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.publicGuidelines),
          icon: const Icon(LucideIcons.search),
          label: const Text('Search guidelines'),
        ),
        AppSpacing.gapLg,
        _GuestFeatureCard(
          icon: LucideIcons.siren,
          title: 'Outbreak and campaign updates',
          description:
              'View current public alerts and situation reports published by the backend.',
          onTap: () => context.push(AppRoutes.outbreakHub),
        ),
        _GuestFeatureCard(
          icon: LucideIcons.bookOpenText,
          title: 'Published guidelines',
          description:
              'Document-aware chapters, tables, figures and source links.',
          onTap: () => context.push(AppRoutes.publicGuidelines),
        ),
        _GuestFeatureCard(
          icon: LucideIcons.cloudDownload,
          title: 'Offline ready',
          description:
              'Public packages remain reusable; private reading data requires sign-in.',
          onTap: () => context.push(AppRoutes.publicGuidelines),
        ),
        _GuestFeatureCard(
          icon: LucideIcons.shieldCheck,
          title: 'Review status is explicit',
          description:
              'The app uses the server publication manifest and never invents review status.',
          onTap: () => context.push(AppRoutes.publicGuidelines),
        ),
      ],
    ),
  );
}

class _GuestFeatureCard extends StatelessWidget {
  const _GuestFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: AppSpacing.md,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: onTap,
    ),
  );
}
