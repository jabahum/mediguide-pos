part of '../screens/guidelines_indexer_page.dart';

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.search);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.search == _textController.text) {
      return;
    }

    _textController.value = TextEditingValue(
      text: widget.search,
      selection: TextSelection.collapsed(offset: widget.search.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _textController.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = _textController.text.trim().isNotEmpty;

    return SearchBar(
      controller: _textController,
      hintText: 'Search guideline sections',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (hasSearch)
          IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _clearSearch();
              setState(() {});
            },
            icon: const Icon(LucideIcons.x),
          ),
      ],
      onChanged: (value) {
        widget.onChanged(value);

        //
        // Rebuild so the clear icon appears/disappears
        // immediately while typing.
        //
        setState(() {});
      },
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
