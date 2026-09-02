part of '../screens/profile_page.dart';

class _ProfileHeaderCard extends ConsumerWidget {
  const _ProfileHeaderCard({required this.onEditProfile});

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    final user = ref.watch(
      authControllerProvider.select((value) => value.valueOrNull?.user),
    );

    final name = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : AppTranslationKey.user.tr;

    final professionalDetails = <String>[
      if (user?.jobTitle.trim().isNotEmpty == true) user!.jobTitle.trim(),

      if (user?.specialization.trim().isNotEmpty == true)
        user!.specialization.trim(),

      if (user?.organization.trim().isNotEmpty == true)
        user!.organization.trim(),
    ];

    final avatarUrl = user?.avatar.isNotEmpty == true
        ? ref.read(backendApiServiceProvider).getFileUrl(filename: user!.avatar)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEditProfile,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              UserAvatar(
                name: name,
                avatarUrl: avatarUrl,
                radius: Responsive.doubleValue(
                  context,
                  mobile: 34,
                  tablet: 40,
                  desktop: 44,
                ),
              ),

              AppSpacing.md.gap,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (professionalDetails.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        professionalDetails.take(2).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          LucideIcons.pencil,
                          size: 13,
                          color: colors.primary,
                        ),

                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            'Edit profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              AppSpacing.sm.gap,

              Icon(LucideIcons.chevronRight, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// SETTINGS SECTION
// ===========================================================================
