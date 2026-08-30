part of '../screens/register_page.dart';

class _TermsTextState extends State<_TermsText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();

    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;

    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void didUpdateWidget(covariant _TermsText oldWidget) {
    super.didUpdateWidget(oldWidget);

    _termsRecognizer.onTap = widget.onTermsTap;

    _privacyRecognizer.onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final normalStyle = theme.textTheme.bodySmall;

    final linkStyle = normalStyle?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'I agree to the ', style: normalStyle),

          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),

          TextSpan(text: ' and ', style: normalStyle),

          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// OR DIVIDER
// ============================================================================
