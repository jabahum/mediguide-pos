part of '../screens/terms_and_conditions_page.dart';

class _LegalDocumentHeader extends StatelessWidget {
  const _LegalDocumentHeader({required this.lastUpdated});

  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final formattedDate =
        '${lastUpdated.day.toString().padLeft(2, '0')}/'
        '${lastUpdated.month.toString().padLeft(2, '0')}/'
        '${lastUpdated.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.scale, color: colors.primary, size: 23),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.termsAndConditions.tr,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Please review these terms before using MediGuide.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                AppSpacing.gapSm,

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.calendarDays,
                        size: 13,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${AppTranslationKey.lastUpdated.tr}: $formattedDate',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

// ===========================================================================
// LEGAL SECTION
// ===========================================================================

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.children,
  });

  final String number;
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: colors.primary, size: 19),
            ),

            AppSpacing.hGapSm,

            Expanded(
              child: Text(
                '$number. $title',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),

        AppSpacing.gapMd,

        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) AppSpacing.gapMd,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// PARAGRAPH
// ===========================================================================

class _LegalParagraph extends StatelessWidget {
  const _LegalParagraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.55,
      ),
    );
  }
}

// ===========================================================================
// SUBHEADING
// ===========================================================================

class _LegalSubheading extends StatelessWidget {
  const _LegalSubheading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ===========================================================================
// BULLET LIST
// ===========================================================================

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  items[index],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          if (index < items.length - 1) AppSpacing.gapSm,
        ],
      ],
    );
  }
}

// ===========================================================================
// CLINICAL / LEGAL NOTICE
// ===========================================================================

class _LegalNotice extends StatelessWidget {
  const _LegalNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.onTertiaryContainer),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CONTACT
// ===========================================================================

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: LucideIcons.landmark,
            label: 'Organization',
            value: 'Ministry of Health Uganda',
          ),

          Divider(height: 1, indent: 56, color: colors.outlineVariant),

          const _ContactRow(
            icon: LucideIcons.mail,
            label: 'Email',
            value: 'support@health.go.ug',
            selectable: true,
          ),

          Divider(height: 1, indent: 56, color: colors.outlineVariant),

          const _ContactRow(
            icon: LucideIcons.globe,
            label: 'Website',
            value: 'www.health.go.ug',
            selectable: true,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),

          AppSpacing.hGapMd,

          SizedBox(
            width: 82,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: selectable
                ? SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// DIVIDER
// ===========================================================================

class _LegalDivider extends StatelessWidget {
  const _LegalDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// ===========================================================================
// FOOTER
// ===========================================================================

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;

    return Column(
      children: [
        Icon(LucideIcons.shieldCheck, size: 22, color: colors.primary),

        AppSpacing.gapSm,

        Text(
          'MediGuide',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 4),

        Text(
          '© $currentYear Ministry of Health Uganda. All rights reserved.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),

        const SizedBox(height: 4),

        Text(
          'Technical implementation and ownership statements should follow the approved MediGuide governance arrangement.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
