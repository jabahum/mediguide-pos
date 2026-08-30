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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.pencil,
                          size: 13,
                          color: colors.primary,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          'Edit profile',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),

              if (description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 2),

                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        AppSpacing.gapSm,

        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],

                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 68,
                      color: colors.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SETTINGS TILE
// ===========================================================================

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.iconColor,
    this.titleColor,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  final VoidCallback? onTap;

  final Widget? trailing;

  final bool showChevron;
  final bool enabled;

  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final effectiveIconColor = enabled
        ? iconColor ?? colors.primary
        : colors.onSurfaceVariant.withValues(alpha: 0.45);

    final effectiveTitleColor = enabled
        ? titleColor
        : colors.onSurfaceVariant.withValues(alpha: 0.6);

    return Semantics(
      button: onTap != null,
      enabled: enabled && onTap != null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 19),
              ),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: effectiveTitleColor,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.hGapSm,

              trailing ??
                  (showChevron && onTap != null
                      ? Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
