part of '../screens/publication_guideline_page.dart';

class _KeyPointList extends StatelessWidget {
  const _KeyPointList({required this.blocks});

  final List<CalloutGuidelineBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key points',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        AppSpacing.gapSm,

        if (blocks.isEmpty) const Text('No reviewed key points available.'),

        for (final block in blocks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(LucideIcons.circleCheck),
              title: Text(
                block.payload.title.isEmpty ? 'Key point' : block.payload.title,
              ),
              subtitle: Text(block.payload.content),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// TABLES
// =============================================================================
