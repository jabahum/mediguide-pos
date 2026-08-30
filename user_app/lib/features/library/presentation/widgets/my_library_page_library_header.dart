part of '../screens/my_library_page.dart';

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.onSearch, required this.onOptions});

  final VoidCallback onSearch;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                'Saved guidelines, notes and reading activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Search library',
          onPressed: onSearch,
          icon: const Icon(LucideIcons.search),
        ),

        IconButton(
          tooltip: 'Library options',
          onPressed: onOptions,
          icon: const Icon(LucideIcons.ellipsis),
        ),
      ],
    );
  }
}
