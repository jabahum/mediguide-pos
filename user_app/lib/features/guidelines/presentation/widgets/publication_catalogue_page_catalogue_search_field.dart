part of '../screens/publication_catalogue_page.dart';

class _CatalogueSearchField extends StatelessWidget {
  const _CatalogueSearchField({
    required this.controller,
    required this.hasSearch,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasSearch;

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SearchBar(
      controller: controller,
      hintText: 'Search published guidelines',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (hasSearch)
          IconButton(
            tooltip: 'Clear search',
            onPressed: onClear,
            icon: const Icon(LucideIcons.x),
          ),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
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
