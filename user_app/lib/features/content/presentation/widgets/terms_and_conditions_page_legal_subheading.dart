part of '../screens/terms_and_conditions_page.dart';

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
