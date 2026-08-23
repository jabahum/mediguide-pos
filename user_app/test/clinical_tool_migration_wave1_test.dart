import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';
import 'package:user_app/features/calculators/domain/clinical_tool_evaluator.dart';

void main() {
  const files = [
    'apgar-score-calculator',
    'blood-pressure-assessment',
    'bmi-calculator',
    'glasgow-coma-scale',
  ];

  for (final file in files) {
    final envelope = Map<String, dynamic>.from(
      jsonDecode(
            File(
              '../clinical-tools/migrations/v1/definitions/$file.json',
            ).readAsStringSync(),
          )
          as Map,
    );
    final definitionJson = Map<String, dynamic>.from(
      envelope['definition'] as Map,
    );
    final definition = ClinicalToolDefinition.fromJson(definitionJson);
    final parity = Map<String, dynamic>.from(
      jsonDecode(
            File(
              '../clinical-tools/migrations/v1/parity/$file.json',
            ).readAsStringSync(),
          )
          as Map,
    );

    test('$file remains explicitly unapproved', () {
      expect(parity['status'], 'changes_required');
      expect(parity['reviewer_id'], isNull);
      expect(parity['reviewed_at'], isNull);
    });

    for (final caseValue in definitionJson['test_cases'] as List<dynamic>) {
      final fixture = Map<String, dynamic>.from(caseValue as Map);
      test('$file: ${fixture['key']}', () {
        final result = const ClinicalToolEvaluator().evaluate(
          definition,
          Map<String, Object?>.from(fixture['inputs'] as Map),
        );
        final expected = Map<String, dynamic>.from(
          fixture['expected'] as Map,
        );
        final outputKeys = definition.outputs
            .map((output) => output.key)
            .toSet();
        final tolerance =
            (fixture['numeric_tolerance'] as num?)?.toDouble() ?? 0;
        for (final entry in expected.entries) {
          if (!outputKeys.contains(entry.key)) continue;
          if (entry.value is num) {
            expect(
              result.values[entry.key],
              isA<num>().having(
                (value) => value.toDouble(),
                entry.key,
                closeTo((entry.value as num).toDouble(), tolerance),
              ),
            );
          } else {
            expect(result.values[entry.key], entry.value);
          }
        }
        final interpretationKeys = expected['interpretations'] as List?;
        if (interpretationKeys != null) {
          expect(result.interpretation?.key, interpretationKeys.first);
        }
        final warningKeys = expected['warnings'] as List?;
        if (warningKeys != null) {
          expect(
            result.warnings.map((warning) => warning.key),
            warningKeys,
          );
        }
      });
    }
  }
}
