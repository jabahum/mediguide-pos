part of '../screens/onboarding_page.dart';

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
