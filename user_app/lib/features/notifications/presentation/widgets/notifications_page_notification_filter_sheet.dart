part of '../screens/notifications_page.dart';

class _NotificationFilterSheet extends ConsumerWidget {
  const _NotificationFilterSheet();

  static const _typeOptions = [
    _NotificationFilterOption(
      label: 'All',
      value: '',
      icon: LucideIcons.layers,
    ),
    _NotificationFilterOption(
      label: 'Info',
      value: 'info',
      icon: LucideIcons.info,
    ),
    _NotificationFilterOption(
      label: 'Success',
      value: 'success',
      icon: LucideIcons.circleCheck,
    ),
    _NotificationFilterOption(
      label: 'Warning',
      value: 'warning',
      icon: LucideIcons.triangleAlert,
    ),
    _NotificationFilterOption(
      label: 'Error',
      value: 'error',
      icon: LucideIcons.circleX,
    ),
  ];

  static const _priorityOptions = [
    _NotificationFilterOption(
      label: 'All',
      value: '',
      icon: LucideIcons.layers,
    ),
    _NotificationFilterOption(
      label: 'Low',
      value: 'low',
      icon: LucideIcons.arrowDown,
    ),
    _NotificationFilterOption(
      label: 'Normal',
      value: 'normal',
      icon: LucideIcons.minus,
    ),
    _NotificationFilterOption(
      label: 'High',
      value: 'high',
      icon: LucideIcons.arrowUp,
    ),
    _NotificationFilterOption(
      label: 'Urgent',
      value: 'urgent',
      icon: LucideIcons.siren,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    final controller = ref.read(notificationsControllerProvider.notifier);

    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =================================================================
          // HEADER
          // =================================================================
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  color: colors.primary,
                  size: 20,
                ),
              ),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Narrow alerts by type and priority.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.gapLg,

          // =================================================================
          // TYPE
          // =================================================================
          const _FilterSectionTitle(title: 'Type', icon: LucideIcons.bell),

          AppSpacing.gapSm,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _typeOptions)
                _FilterChoiceChip(
                  label: option.label,
                  icon: option.icon,
                  selected: state.selectedType == option.value,
                  onTap: () {
                    controller.setTypeFilter(option.value);
                  },
                ),
            ],
          ),

          AppSpacing.gapLg,

          // =================================================================
          // PRIORITY
          // =================================================================
          const _FilterSectionTitle(
            title: 'Priority',
            icon: LucideIcons.triangleAlert,
          ),

          AppSpacing.gapSm,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _priorityOptions)
                _FilterChoiceChip(
                  label: option.label,
                  icon: option.icon,
                  selected: state.selectedPriority == option.value,
                  onTap: () {
                    controller.setPriorityFilter(option.value);
                  },
                ),
            ],
          ),

          AppSpacing.gapLg,

          // =================================================================
          // ACTIONS
          // =================================================================
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.hasActiveFilters
                      ? () {
                          controller.clearAllFilters();

                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: const Icon(LucideIcons.rotateCcw),
                  label: const Text('Reset'),
                ),
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(LucideIcons.check),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// BROWSE CARD
// ===========================================================================
