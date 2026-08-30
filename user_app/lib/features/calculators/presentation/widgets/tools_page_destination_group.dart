part of '../screens/tools_page.dart';

class _DestinationGroup extends StatelessWidget {
  const _DestinationGroup({
    required this.title,
    required this.items,
    this.description,
  });

  final String title;
  final String? description;
  final List<_Destination> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              if (description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        AppSpacing.gapSm,

        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _DestinationTile(destination: items[index]),

                if (index < items.length - 1)
                  const Divider(height: 1, indent: 68),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DESTINATION TILE
// ============================================================================
