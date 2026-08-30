part of '../screens/tree_selector_page.dart';

class _TreeSearchField extends StatefulWidget {
  const _TreeSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_TreeSearchField> createState() => _TreeSearchFieldState();
}
