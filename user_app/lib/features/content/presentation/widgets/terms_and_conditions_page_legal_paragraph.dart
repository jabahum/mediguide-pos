part of '../screens/terms_and_conditions_page.dart';

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
