part of '../screens/register_page.dart';

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 14, color: colors.onSurfaceVariant),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            'Use at least 8 characters with a letter and a number.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// COUNTRY PICKER
// ============================================================================
