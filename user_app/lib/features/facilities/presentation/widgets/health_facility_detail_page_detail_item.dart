part of '../screens/health_facility_detail_page.dart';

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    this.mono = false,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final displayValue = value.trim().isEmpty ? '—' : value.trim();

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.35,
      fontFamily: mono ? 'monospace' : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: selectable
                ? SelectableText(displayValue, style: valueStyle)
                : Text(displayValue, style: valueStyle),
          ),
        ],
      ),
    );
  }
}
