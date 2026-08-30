part of '../screens/onboarding_page.dart';

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
