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

class _ClinicalIllustration extends StatelessWidget {
  const _ClinicalIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      image: true,
      label:
          'Clinical guidance illustration showing guidelines, safety, health and facilities.',
      child: SizedBox(
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ----------------------------------------------------------------
            // Outer glow
            // ----------------------------------------------------------------
            Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),

            // ----------------------------------------------------------------
            // Main circle
            // ----------------------------------------------------------------
            Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),

            Icon(LucideIcons.stethoscope, size: 72, color: colors.primary),

            const _OrbitIcon(
              alignment: Alignment(-0.92, -0.78),
              icon: LucideIcons.bookOpenText,
            ),

            const _OrbitIcon(
              alignment: Alignment(0.92, -0.78),
              icon: LucideIcons.shieldCheck,
            ),

            const _OrbitIcon(
              alignment: Alignment(-0.92, 0.78),
              icon: LucideIcons.heartPulse,
            ),

            const _OrbitIcon(
              alignment: Alignment(0.92, 0.78),
              icon: LucideIcons.hospital,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ORBIT ICON
// ============================================================================

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({required this.alignment, required this.icon});

  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: colors.primary, size: 21),
      ),
    );
  }
}

// ============================================================================
// BENEFITS
// ============================================================================

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: const Column(
        children: [
          _Benefit(
            icon: LucideIcons.shieldCheck,
            title: 'Trusted guidance',
            description:
                'Reviewed clinical guidance from approved health sources.',
          ),

          _BenefitDivider(),

          _Benefit(
            icon: LucideIcons.cloudDownload,
            title: 'Available offline',
            description:
                'Save supported guidelines for reliable access when connectivity is limited.',
          ),

          _BenefitDivider(),

          _Benefit(
            icon: LucideIcons.bellRing,
            title: 'Stay up to date',
            description:
                'Access newly published guidance, outbreak updates and situation reports.',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BENEFIT
// ============================================================================

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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DIVIDER
// ============================================================================

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ============================================================================
// GUEST NOTICE
// ============================================================================

class _GuestAccessNotice extends StatelessWidget {
  const _GuestAccessNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Guest access allows public clinical content. Sign in for bookmarks, notes, downloads and synchronization.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.info,
              size: 19,
              color: colors.onSecondaryContainer,
            ),

            AppSpacing.hGapSm,

            Expanded(
              child: Text(
                'Guest access includes public clinical content. '
                'Sign in to sync bookmarks, notes, reading progress '
                'and offline downloads.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
