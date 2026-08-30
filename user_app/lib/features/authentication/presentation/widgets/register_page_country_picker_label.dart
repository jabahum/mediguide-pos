part of '../screens/register_page.dart';

class _CountryPickerLabel extends StatelessWidget {
  const _CountryPickerLabel({required this.flag, required this.code});

  final Widget flag;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 20, height: 14, child: flag),

        const SizedBox(width: 4),

        Text(code, style: context.textTheme.bodyMedium),
      ],
    );
  }
}

// ============================================================================
// TERMS
// ============================================================================
