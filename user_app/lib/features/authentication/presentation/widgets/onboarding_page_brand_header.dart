part of '../screens/onboarding_page.dart';

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      header: true,
      label: 'MediGuide. Official Uganda Clinical Guidelines.',
      child: Column(
        children: [
          const AppLogo(logoSize: 86),

          AppSpacing.gapSm,

          Text(
            'MediGuide',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Uganda Clinical Guidelines',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CLINICAL ILLUSTRATION
// ============================================================================
