part of '../screens/guidelines_page.dart';

class _GuidelinesSearchBox extends StatefulWidget {
  const _GuidelinesSearchBox({
    required this.searchQuery,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String searchQuery;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_GuidelinesSearchBox> createState() => _GuidelinesSearchBoxState();
}
