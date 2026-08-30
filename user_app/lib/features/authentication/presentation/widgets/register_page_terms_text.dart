part of '../screens/register_page.dart';

class _TermsText extends StatefulWidget {
  const _TermsText({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_TermsText> createState() => _TermsTextState();
}
