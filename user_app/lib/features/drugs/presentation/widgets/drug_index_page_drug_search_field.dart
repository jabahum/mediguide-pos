part of '../screens/drug_index_page.dart';

class _DrugSearchField extends StatefulWidget {
  const _DrugSearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  State<_DrugSearchField> createState() => _DrugSearchFieldState();
}
