part of '../screens/edit_profile_page.dart';

class _UnsavedChangesNotice extends StatelessWidget {
  const _UnsavedChangesNotice({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circleDot,
            size: 18,
            color: colors.onSecondaryContainer,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              'You have unsaved changes.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: isSaving ? null : onSave,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
