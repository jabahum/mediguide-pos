import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/presentation/widgets/responsive_clinical_table.dart';

void main() {
  testWidgets('wide clinical tables use labelled row cards without horizontal scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: ResponsiveClinicalTable(
              payload: GuidelineTablePayload(
                title: 'Diagnostic tests',
                columns: ['Test', 'Typical setting', 'Result'],
                rows: [
                  ['RDT', 'Point of care', 'Antigen detection'],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DataTable), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );
    expect(find.text('Typical setting'), findsOneWidget);
    expect(find.text('Point of care'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-column clinical tables keep a wrapping table layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: ResponsiveClinicalTable(
              payload: GuidelineTablePayload(
                columns: ['Abbreviation', 'Meaning'],
                rows: [
                  ['HbA1c', 'Glycated haemoglobin'],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Glycated haemoglobin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
