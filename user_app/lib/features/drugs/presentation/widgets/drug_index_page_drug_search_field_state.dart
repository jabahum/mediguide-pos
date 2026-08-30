part of '../screens/drug_index_page.dart';

class _DrugSearchFieldState extends State<_DrugSearchField> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = widget.controller.text.trim().isNotEmpty;

    return SearchBar(
      controller: widget.controller,
      hintText: 'Search medicines',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (hasSearch)
          IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              widget.onClear();
              setState(() {});
            },
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
// ACTIVE FILTERS
// ===========================================================================
