import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';
import 'package:user_app/features/calculators/domain/clinical_tool_evaluator.dart';

void main() {
  test('native evaluator produces a typed result and interpretation', () {
    const definition = ClinicalToolDefinition(
      schemaVersion: '1.0',
      toolType: 'calculator',
      title: 'BMI',
      version: '1.0.0',
      inputs: [
        ClinicalToolInput(
          key: 'weight',
          type: 'number',
          label: 'Weight',
          required: true,
        ),
        ClinicalToolInput(
          key: 'height',
          type: 'number',
          label: 'Height',
          required: true,
        ),
      ],
      calculations: [
        ClinicalToolCalculation(
          key: 'bmi',
          expression: ClinicalToolExpression(
            op: 'divide',
            args: [
              ClinicalToolExpression(op: 'field', field: 'weight'),
              ClinicalToolExpression(
                op: 'multiply',
                args: [
                  ClinicalToolExpression(op: 'field', field: 'height'),
                  ClinicalToolExpression(op: 'field', field: 'height'),
                ],
              ),
            ],
          ),
        ),
      ],
      outputs: [
        ClinicalToolOutput(
          key: 'result',
          label: 'BMI',
          value: ClinicalToolExpression(
            op: 'round',
            precision: 1,
            args: [ClinicalToolExpression(op: 'field', field: 'bmi')],
          ),
        ),
      ],
      interpretations: [
        ClinicalToolInterpretation(
          key: 'high',
          when: ClinicalToolExpression(
            op: 'greater_than_or_equal',
            args: [
              ClinicalToolExpression(op: 'field', field: 'result'),
              ClinicalToolExpression(op: 'literal', value: 25),
            ],
          ),
          label: 'Above healthy range',
          recommendations: ['Review clinically'],
        ),
      ],
      completion: ClinicalToolCompletion(mode: 'none'),
    );
    final result = const ClinicalToolEvaluator().evaluate(definition, {
      'weight': 80,
      'height': 1.7,
    });
    expect(result.values['result'], 27.7);
    expect(result.interpretation?.key, 'high');
  });

  test('native evaluator rejects unknown operations', () {
    const definition = ClinicalToolDefinition(
      schemaVersion: '1.0',
      toolType: 'calculator',
      title: 'Unsafe',
      version: '1.0.0',
      outputs: [
        ClinicalToolOutput(
          key: 'result',
          label: 'Result',
          value: ClinicalToolExpression(op: 'eval', value: 'bad'),
        ),
      ],
      completion: ClinicalToolCompletion(mode: 'none'),
    );
    expect(
      () => const ClinicalToolEvaluator().evaluate(definition, const {}),
      throwsUnsupportedError,
    );
  });

  test('normalizes entered measurement units before evaluation', () {
    const definition = ClinicalToolDefinition(
      schemaVersion: '1.0',
      toolType: 'calculator',
      title: 'Weight',
      version: '1.0.0',
      inputs: [
        ClinicalToolInput(
          key: 'weight',
          type: 'number',
          label: 'Weight',
          required: true,
          defaultUnit: 'kg',
          allowedUnits: ['kg', 'lb'],
        ),
      ],
      outputs: [
        ClinicalToolOutput(
          key: 'result',
          label: 'Weight',
          value: ClinicalToolExpression(
            op: 'round',
            precision: 2,
            args: [ClinicalToolExpression(op: 'field', field: 'weight')],
          ),
        ),
      ],
      completion: ClinicalToolCompletion(mode: 'none'),
    );
    final result = const ClinicalToolEvaluator().evaluate(definition, {
      'weight': {'value': 100, 'unit': 'lb'},
    });
    expect(result.values['result'], 45.36);
  });
}
