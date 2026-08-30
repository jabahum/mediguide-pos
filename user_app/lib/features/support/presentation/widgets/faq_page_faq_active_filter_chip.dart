part of '../screens/faq_page.dart';

class _FaqActiveFilterChip extends StatelessWidget {
  const _FaqActiveFilterChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InputChip(
      avatar: Icon(
        LucideIcons.search,
        size: 14,
        color: colors.onSecondaryContainer,
      ),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onDeleted: onClear,
      deleteIcon: const Icon(LucideIcons.x, size: 14),
      backgroundColor: colors.surface.withValues(alpha: 0.65),
      side: BorderSide.none,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ===========================================================================
// FAQ ITEM SHELL
// ===========================================================================
