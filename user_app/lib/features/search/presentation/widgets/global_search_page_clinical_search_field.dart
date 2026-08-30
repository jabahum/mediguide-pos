part of '../screens/global_search_page.dart';

class _ClinicalSearchField extends StatelessWidget {
  const _ClinicalSearchField({
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SearchBar(
      controller: controller,
      hintText: 'Search outbreaks, guidelines, drugs, tools…',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (controller.text.isNotEmpty)
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

/// ===========================================================================
/// FILTERS
/// ===========================================================================
