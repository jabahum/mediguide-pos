part of '../screens/profile_page.dart';

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
