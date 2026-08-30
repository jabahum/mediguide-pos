part of '../screens/guest_more_page.dart';

class _GuestAccountCard extends StatelessWidget {
  const _GuestAccountCard({required this.onSignIn, required this.onRegister});

  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------
          // ICON + TITLE
          // ---------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(LucideIcons.userRound, color: cs.primary, size: 24),
              ),

              AppSpacing.gapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get more from MediGuide',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to personalize your clinical reference experience.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.gapLg,

          // ---------------------------------------------------------
          // BENEFITS
          // ---------------------------------------------------------
          const _AccountBenefit(
            icon: LucideIcons.bookmark,
            text: 'Save bookmarks and notes',
          ),
          const SizedBox(height: 10),

          const _AccountBenefit(
            icon: LucideIcons.history,
            text: 'Sync your reading progress',
          ),
          const SizedBox(height: 10),

          const _AccountBenefit(
            icon: LucideIcons.cloudDownload,
            text: 'Manage downloaded content',
          ),
          const SizedBox(height: 10),

          const _AccountBenefit(
            icon: LucideIcons.bell,
            text: 'Receive important updates',
          ),

          AppSpacing.gapLg,

          // ---------------------------------------------------------
          // ACTIONS
          // ---------------------------------------------------------
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(LucideIcons.logIn, size: 18),
              label: const Text('Sign in'),
            ),
          ),

          AppSpacing.gapSm,

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRegister,
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACCOUNT BENEFIT
// ============================================================================
