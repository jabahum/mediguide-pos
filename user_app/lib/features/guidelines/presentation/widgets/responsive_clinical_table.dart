import 'package:flutter/material.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';

/// Renders reviewed clinical tables without requiring horizontal scrolling.
///
/// Two-column tables retain a conventional table layout. Wider tables become
/// labelled row cards so every value remains associated with its column header
/// on narrow screens and at large accessibility text scales.
class ResponsiveClinicalTable extends StatelessWidget {
  const ResponsiveClinicalTable({
    super.key,
    required this.payload,
    this.showTitle = false,
  });

  final GuidelineTablePayload payload;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final columns = payload.columns;
    final rows = payload.rows;

    if (columns.isEmpty) {
      return const Text('This table has no columns.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRowCards = columns.length > 2 || constraints.maxWidth < 360;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle && payload.title.trim().isNotEmpty) ...[
              Text(
                payload.title.trim(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.gapSm,
            ],
            if (useRowCards)
              _TableRowCards(columns: columns, rows: rows)
            else
              _WrappingTable(columns: columns, rows: rows),
          ],
        );
      },
    );
  }
}

class _WrappingTable extends StatelessWidget {
  const _WrappingTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        border: TableBorder.all(color: colors.outlineVariant),
        columnWidths: {
          for (var index = 0; index < columns.length; index++)
            index: const FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          TableRow(
            decoration: BoxDecoration(color: colors.surfaceContainerHigh),
            children: [
              for (final column in columns)
                _TableCell(text: column, isHeader: true),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                for (var index = 0; index < columns.length; index++)
                  _TableCell(text: index < row.length ? row[index] : ''),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableRowCards extends StatelessWidget {
  const _TableRowCards({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
          Padding(
            padding: EdgeInsets.only(
              bottom: rowIndex == rows.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: Semantics(
              label: 'Table row ${rowIndex + 1}',
              child: Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (
                      var columnIndex = 0;
                      columnIndex < columns.length;
                      columnIndex++
                    ) ...[
                      Text(
                        columns[columnIndex],
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SelectableText(
                        columnIndex < rows[rowIndex].length
                            ? rows[rowIndex][columnIndex]
                            : '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (columnIndex < columns.length - 1) ...[
                        AppSpacing.gapSm,
                        Divider(color: colors.outlineVariant),
                        AppSpacing.gapSm,
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.text, this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: SelectableText(
      text,
      style: isHeader
          ? Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)
          : Theme.of(context).textTheme.bodySmall,
    ),
  );
}
