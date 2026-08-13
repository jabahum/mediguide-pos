import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/storage/local_storage_service.dart';

/// A focused first-run screen that explains trust, offline access and update
/// behavior before allowing either guest exploration or authentication.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 44)
                      .clamp(0, double.infinity)
                      .toDouble(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandLockup(),
                    const SizedBox(height: 28),
                    const _ClinicalIllustration(),
                    const SizedBox(height: 28),
                    const _Benefit(
                      icon: LucideIcons.shieldCheck,
                      title: 'Trusted',
                      description:
                          'Official, reviewed clinical guidance for healthcare teams.',
                    ),
                    const SizedBox(height: 16),
                    const _Benefit(
                      icon: LucideIcons.mapPin,
                      title: 'Accessible',
                      description: 'Use essential content online or offline.',
                    ),
                    const SizedBox(height: 16),
                    const _Benefit(
                      icon: LucideIcons.bellRing,
                      title: 'Always updated',
                      description:
                          'Receive the latest guideline and situation-report updates.',
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => _complete(context, AppRoutes.home),
                      child: const Text('Explore as Guest'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => _complete(context, AppRoutes.login),
                      child: const Text('Sign In / Register'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 18,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        for (var index = 0; index < 3; index++) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context, String fallback) async {
    final requested = GoRouterState.of(context).uri.queryParameters['redirect'];
    await PreferenceUtils.setBool(SharedPreferencesKeys.notFirstTime, true);
    if (!context.mounted) return;
    context.go(
      requested == null ? fallback : AppRoutes.safeDestination(requested),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final mark = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(LucideIcons.bookOpenText, color: colors.onPrimary, size: 25),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MediGuide', style: Theme.of(context).textTheme.headlineSmall),
        Text(
          'Official Uganda Clinical\nGuidelines App',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
    if (stacked) {
      return Column(
        children: [
          mark,
          AppSpacing.gapSm,
          DefaultTextStyle.merge(textAlign: TextAlign.center, child: title),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mark,
        AppSpacing.gapSm,
        Flexible(child: title),
      ],
    );
  }
}

class _ClinicalIllustration extends StatelessWidget {
  const _ClinicalIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 164,
            height: 164,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Icon(LucideIcons.stethoscope, size: 82, color: colors.primary),
          const _OrbitIcon(
            alignment: Alignment.topLeft,
            icon: LucideIcons.bookOpen,
          ),
          const _OrbitIcon(
            alignment: Alignment.topRight,
            icon: LucideIcons.shieldCheck,
          ),
          const _OrbitIcon(
            alignment: Alignment.bottomLeft,
            icon: LucideIcons.heartPulse,
          ),
          const _OrbitIcon(
            alignment: Alignment.bottomRight,
            icon: LucideIcons.hospital,
          ),
        ],
      ),
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({required this.alignment, required this.icon});
  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
