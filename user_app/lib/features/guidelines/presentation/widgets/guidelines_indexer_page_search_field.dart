part of '../screens/guidelines_indexer_page.dart';

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.search,
    required this.onChanged,
    required this.onClear,
  });

  final String search;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}
