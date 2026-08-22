import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';
import 'package:user_app/features/calculators/presentation/widgets/native_clinical_tool.dart';

void main() {
  const definition = ClinicalToolDefinition(
    schemaVersion: '1.0',
    toolType: 'calculator',
    title: 'Dose helper',
    description: 'A native clinical tool.',
    version: '1.0.0',
    warnings: [
      ClinicalToolMessage(
        key: 'warning',
        text: 'Confirm the patient details.',
        severity: 'warning',
      ),
    ],
    inputs: [
      ClinicalToolInput(
        key: 'weight',
        type: 'number',
        label: 'Weight',
        required: true,
        defaultUnit: 'kg',
      ),
    ],
    outputs: [
      ClinicalToolOutput(
        key: 'result',
        label: 'Dose',
        unit: 'mg',
        value: ClinicalToolExpression(
          op: 'multiply',
          args: [
            ClinicalToolExpression(op: 'field', field: 'weight'),
            ClinicalToolExpression(op: 'literal', value: 2),
          ],
        ),
      ),
    ],
    completion: ClinicalToolCompletion(mode: 'none'),
  );

  testWidgets(
    'renders and calculates natively at large text scale in dark mode',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              splashFactory: NoSplash.splashFactory,
            ),
            home: const Scaffold(
              body: NativeClinicalTool(definition: definition),
            ),
          ),
        ),
      );
      expect(find.text('Confirm the patient details.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '30');
      await tester.tap(find.text('Calculate'));
      await tester.pump();
      expect(find.textContaining('Dose: 60'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('restores workflow values and reports changes', (tester) async {
    Map<String, Object?>? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: NativeClinicalTool(
            definition: definition,
            initialValues: const {'weight': 45},
            onChanged: (value) => saved = value,
          ),
        ),
      ),
    );
    expect(find.text('45'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '50');
    expect(saved?['weight'], 50);
  });
}
