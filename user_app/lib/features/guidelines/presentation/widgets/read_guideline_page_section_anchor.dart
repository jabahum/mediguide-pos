part of '../screens/read_guideline_page.dart';

class _SectionAnchor extends StatelessWidget {
  const _SectionAnchor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(container: true, child: child);
  }
}

// ===========================================================================
// NO STRUCTURED SECTIONS
// ===========================================================================
