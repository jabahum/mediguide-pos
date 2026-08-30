part of '../screens/guidelines_page.dart';

class _GuidelinesSearchBoxState extends State<_GuidelinesSearchBox> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _GuidelinesSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_textController.text == widget.searchQuery) {
      return;
    }

    _textController.value = TextEditingValue(
      text: widget.searchQuery,
      selection: TextSelection.collapsed(offset: widget.searchQuery.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _textController.clear();

    widget.onChanged('');

    widget.onSubmitted('');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = _textController.text.trim().isNotEmpty;

    return SearchBar(
      controller: _textController,
      hintText: 'Search guidelines, conditions, ICD codes…',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (hasSearch)
          IconButton(
            tooltip: 'Clear search',
            onPressed: _clearSearch,
            icon: const Icon(LucideIcons.x),
          ),
      ],
      onChanged: (value) {
        widget.onChanged(value);

        setState(() {});
      },
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
      side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}

// ===========================================================================
// QUICK FILTERS
// ===========================================================================
