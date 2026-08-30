part of '../screens/publication_guideline_page.dart';

class _TableList extends StatelessWidget {
  const _TableList({required this.tables});

  final List<TableGuidelineBlock> tables;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tables',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        AppSpacing.gapSm,

        if (tables.isEmpty) const Text('No reviewed tables available.'),

        for (final table in tables)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(LucideIcons.table2),
              title: Text(
                table.payload.title.isEmpty
                    ? 'Clinical table'
                    : table.payload.title,
              ),
              subtitle: Text(
                '${table.payload.rows.length} rows'
                ' • '
                '${table.payload.columns.length} columns',
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// REVIEW STATUS
// =============================================================================
