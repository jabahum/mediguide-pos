part of '../screens/terms_and_conditions_page.dart';

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
