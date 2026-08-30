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

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({
    required this.hasPermanentFilter,
    required this.hasActiveFilters,
    required this.showHighPriorityOnly,
    required this.isEmergencyRoute,
    required this.targetPopulation,
    required this.onShowAll,
    required this.onToggleHighPriority,
    required this.onEmergency,
    required this.onTargetPopulation,
  });

  final bool hasPermanentFilter;
  final bool hasActiveFilters;
  final bool showHighPriorityOnly;
  final bool isEmergencyRoute;
  final String targetPopulation;

  final VoidCallback onShowAll;
  final VoidCallback onToggleHighPriority;
  final VoidCallback onEmergency;
  final ValueChanged<String> onTargetPopulation;

  @override
  Widget build(BuildContext context) {
    final normalizedPopulation = targetPopulation.toLowerCase();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: LucideIcons.library,
            selected: !hasPermanentFilter && !hasActiveFilters,
            onTap: onShowAll,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'High Priority',
            icon: LucideIcons.triangleAlert,
            selected: showHighPriorityOnly,
            onTap: onToggleHighPriority,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Emergency',
            icon: LucideIcons.siren,
            selected: isEmergencyRoute,
            onTap: onEmergency,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Children',
            icon: LucideIcons.baby,
            selected: normalizedPopulation.contains('children'),
            onTap: () {
              onTargetPopulation(
                normalizedPopulation.contains('children') ? '' : 'Children',
              );
            },
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Adults',
            icon: LucideIcons.user,
            selected: normalizedPopulation.contains('adult'),
            onTap: () {
              onTargetPopulation(
                normalizedPopulation.contains('adult') ? '' : 'Adults',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        onTap();
      },
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? colors.onPrimary : colors.primary,
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? colors.onPrimary : colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceContainerLowest,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

// ===========================================================================
// ACTIVE CONTEXT
// ===========================================================================

class _ActiveGuidelineContext extends StatelessWidget {
  const _ActiveGuidelineContext({
    required this.title,
    required this.hasPermanentFilter,
    required this.hasFilters,
    required this.searchQuery,
    required this.showHighPriorityOnly,
    required this.isEmergencyRoute,
    required this.targetPopulation,
    required this.onClearFilters,
    required this.onShowAll,
  });

  final String title;
  final bool hasPermanentFilter;
  final bool hasFilters;

  final String searchQuery;
  final bool showHighPriorityOnly;
  final bool isEmergencyRoute;
  final String targetPopulation;

  final VoidCallback onClearFilters;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSpecificFilters =
        searchQuery.trim().isNotEmpty ||
        showHighPriorityOnly ||
        isEmergencyRoute ||
        targetPopulation.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPermanentFilter
                    ? LucideIcons.folderOpen
                    : LucideIcons.listFilter,
                size: 17,
                color: colors.onSecondaryContainer,
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  hasPermanentFilter ? title : 'Filters applied',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (hasFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear'),
                ),

              if (hasPermanentFilter)
                TextButton(onPressed: onShowAll, child: const Text('Show all')),
            ],
          ),

          if (hasSpecificFilters)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (searchQuery.trim().isNotEmpty)
                  _ContextBadge(
                    icon: LucideIcons.search,
                    label: '"${searchQuery.trim()}"',
                  ),

                if (showHighPriorityOnly)
                  const _ContextBadge(
                    icon: LucideIcons.triangleAlert,
                    label: 'High Priority',
                  ),

                if (isEmergencyRoute)
                  const _ContextBadge(
                    icon: LucideIcons.siren,
                    label: 'Emergency',
                  ),

                if (targetPopulation.trim().isNotEmpty)
                  _ContextBadge(
                    icon: LucideIcons.users,
                    label: targetPopulation,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContextBadge extends StatelessWidget {
  const _ContextBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSecondaryContainer),

          const SizedBox(width: 4),

          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CLICKABLE CARD SHELL
// ===========================================================================

class _GuidelineCardShell extends StatelessWidget {
  const _GuidelineCardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
