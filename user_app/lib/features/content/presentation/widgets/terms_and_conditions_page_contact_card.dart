part of '../screens/terms_and_conditions_page.dart';

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
