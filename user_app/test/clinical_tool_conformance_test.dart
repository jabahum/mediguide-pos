import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';
import 'package:user_app/features/calculators/domain/clinical_tool_evaluator.dart';

void main() {
  final suite =
      jsonDecode(
            File(
              '../clinical-tools/conformance/v1/runtime-fixtures.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  for (final toolValue in suite['tools'] as List<dynamic>) {
    final tool = Map<String, dynamic>.from(toolValue as Map);
    final definition = ClinicalToolDefinition.fromJson(
      Map<String, dynamic>.from(tool['definition'] as Map),
    );
    for (final caseValue in tool['cases'] as List<dynamic>) {
      final fixture = Map<String, dynamic>.from(caseValue as Map);
      test('shared runtime conformance: ${fixture['key']}', () {
        final fixedNow = fixture['fixed_now'] == null
            ? null
            : DateTime.parse(fixture['fixed_now'].toString());
        final evaluator = ClinicalToolEvaluator(fixedNow: fixedNow);
        final input = Map<String, Object?>.from(fixture['input'] as Map);
        if (fixture['expected_error'] != null) {
          expect(
            () => evaluator.evaluate(definition, input),
            throwsA(anything),
          );
          return;
        }
        final result = evaluator.evaluate(definition, input);
        final tolerance =
            (fixture['numeric_tolerance'] as num?)?.toDouble() ?? 0;
        _expectValue(
          result.normalizedInputs,
          Map<String, Object?>.from(
            fixture['expected_normalized_input'] as Map,
          ),
          tolerance,
        );
        _expectValue(
          result.values,
          Map<String, Object?>.from(fixture['expected_outputs'] as Map),
          tolerance,
        );
        expect(
          result.interpretation?.label,
          fixture['expected_interpretation'],
        );
        expect(result.recommendations, fixture['expected_recommendations']);
        expect(
          result.warnings.map((item) => item.text),
          fixture['expected_warnings'],
        );
        if (fixture['expected_checklist'] != null) {
          expect(result.checklist, isNotNull);
          _expectValue(
            result.checklist!.toJson(),
            Map<String, Object?>.from(fixture['expected_checklist'] as Map),
            tolerance,
          );
        }
      });
    }
  }
}

void _expectValue(Object? actual, Object? expected, double tolerance) {
  if (expected is Map) {
    expect(actual, isA<Map>());
    final actualMap = actual! as Map;
    expect(actualMap.keys.toSet(), expected.keys.toSet());
    for (final entry in expected.entries) {
      _expectValue(actualMap[entry.key], entry.value, tolerance);
    }
    return;
  }
  if (expected is num) {
    expect(actual, isA<num>());
    expect(
      (actual! as num).toDouble(),
      closeTo(expected.toDouble(), tolerance),
    );
    return;
  }
  expect(actual, expected);
}
