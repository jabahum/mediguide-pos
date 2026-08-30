part of '../screens/guest_home_page.dart';

class _EmptyPublicationsCard extends StatelessWidget {
  const _EmptyPublicationsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const ClinicalIconTile(icon: LucideIcons.bookOpenText),

              AppSpacing.hGapMd,

              const Expanded(
                child: Text('No published guidelines are currently available.'),
              ),

              const Icon(LucideIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// LOADING
// =============================================================================
