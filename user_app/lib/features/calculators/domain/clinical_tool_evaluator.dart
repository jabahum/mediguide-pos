import 'dart:math' as math;

import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';

final class ClinicalToolResult {
  const ClinicalToolResult({
    required this.values,
    required this.normalizedInputs,
    this.interpretation,
    this.recommendations = const [],
    this.warnings = const [],
    this.checklist,
  });
  final Map<String, Object?> values;
  final Map<String, Object?> normalizedInputs;
  final ClinicalToolInterpretation? interpretation;
  final List<String> recommendations;
  final List<ClinicalToolMessage> warnings;
  final ClinicalToolChecklistProgress? checklist;
}

final class ClinicalToolChecklistProgress {
  const ClinicalToolChecklistProgress({
    required this.completedRequired,
    required this.totalRequired,
    required this.percentage,
    required this.complete,
    required this.needsReview,
    required this.criticalPending,
  });

  final int completedRequired;
  final int totalRequired;
  final double percentage;
  final bool complete;
  final bool needsReview;
  final List<String> criticalPending;

  Map<String, Object?> toJson() => {
    'completed_required': completedRequired,
    'total_required': totalRequired,
    'percentage': percentage,
    'complete': complete,
    'needs_review': needsReview,
    'critical_pending': criticalPending,
  };
}

final class ClinicalToolEvaluator {
  const ClinicalToolEvaluator({this.fixedNow});

  final DateTime? fixedNow;

  ClinicalToolResult evaluate(
    ClinicalToolDefinition definition,
    Map<String, Object?> input,
  ) {
    final values = <String, Object?>{...input};
    final normalizedInputs = <String, Object?>{};
    for (final field in definition.inputs) {
      if (field.required && !values.containsKey(field.key)) {
        throw FormatException('${field.label} is required');
      }
      final value = values[field.key];
      if (value is Map && value['value'] is num) {
        final unit = value['unit']?.toString() ?? field.defaultUnit;
        values[field.key] = _convert(
          (value['value'] as num).toDouble(),
          unit,
          field.defaultUnit,
        );
        normalizedInputs[field.key] = {
          'value': values[field.key],
          'unit': field.defaultUnit,
        };
      } else {
        normalizedInputs[field.key] = value;
      }
      if (value is num && field.minimum != null && value < field.minimum!) {
        throw FormatException('${field.label} is below the minimum');
      }
      if (value is num && field.maximum != null && value > field.maximum!) {
        throw FormatException('${field.label} exceeds the maximum');
      }
    }
    for (final item in definition.calculations) {
      values[item.key] = _expression(item.expression, values);
    }
    final outputs = <String, Object?>{};
    for (final item in definition.outputs) {
      outputs[item.key] = _expression(item.value, values);
    }
    final context = <String, Object?>{...values, ...outputs};
    final interpretationByKey = {
      for (final item in definition.interpretations) item.key: item,
    };
    final warningByKey = {
      for (final item in definition.warnings) item.key: item,
    };
    ClinicalToolInterpretation? interpretation;
    final recommendations = <String>[];
    final warnings = definition.warnings
        .where(
          (warning) =>
              warning.when == null ||
              _truth(_expression(warning.when!, context)),
        )
        .toList();
    final rules = [...definition.rules]
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder == 0 ? a.key.compareTo(b.key) : byOrder;
      });
    var stopped = false;
    for (final rule in rules) {
      if (!_truth(_expression(rule.when, context))) continue;
      for (final action in rule.actions) {
        switch (action.type) {
          case 'set_output':
            final expression = action.value;
            if (expression == null || !outputs.containsKey(action.target)) {
              throw const FormatException('Invalid set_output action');
            }
            outputs[action.target] = _expression(expression, context);
            context[action.target] = outputs[action.target];
            break;
          case 'add_interpretation':
            final item = interpretationByKey[action.target];
            if (item == null) {
              throw FormatException('Unknown interpretation: ${action.target}');
            }
            interpretation ??= item;
            _appendUnique(recommendations, item.recommendations);
            break;
          case 'add_recommendation':
            final item = interpretationByKey[action.target];
            if (item == null) {
              throw FormatException(
                'Unknown recommendation source: ${action.target}',
              );
            }
            _appendUnique(recommendations, item.recommendations);
            break;
          case 'add_warning':
          case 'escalate':
            final item = warningByKey[action.messageKey];
            if (item == null) {
              throw FormatException('Unknown warning: ${action.messageKey}');
            }
            if (!warnings.any((warning) => warning.key == item.key)) {
              warnings.add(item);
            }
            break;
          case 'stop':
            stopped = true;
            break;
        }
      }
      if (stopped || rule.stop) break;
    }
    final interpretations = [...definition.interpretations]
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder == 0 ? a.key.compareTo(b.key) : byOrder;
      });
    for (final item in interpretations) {
      if (_truth(_expression(item.when, context))) {
        interpretation ??= item;
        _appendUnique(recommendations, item.recommendations);
      }
    }
    ClinicalToolChecklistProgress? checklist;
    if (definition.toolType == 'checklist') {
      final required = definition.inputs
          .where((field) => field.type == 'checklist_item' && field.required)
          .toList(growable: false);
      bool responseComplete(Object? value) =>
          value == true ||
          value is num ||
          (value is String && value.isNotEmpty) ||
          (value is List && value.isNotEmpty);
      final completed = required
          .where((field) => responseComplete(input[field.key]))
          .length;
      final criticalPending = required
          .where(
            (field) => field.critical && !responseComplete(input[field.key]),
          )
          .map((field) => field.key)
          .toList(growable: false);
      final needsReview = definition.completion.requireReview;
      checklist = ClinicalToolChecklistProgress(
        completedRequired: completed,
        totalRequired: required.length,
        percentage: required.isEmpty
            ? 100
            : (completed / required.length * 10000).round() / 100,
        complete:
            definition.completion.mode == 'all_required' &&
            completed == required.length &&
            !needsReview &&
            criticalPending.isEmpty,
        needsReview: needsReview,
        criticalPending: List.unmodifiable(criticalPending),
      );
    }
    return ClinicalToolResult(
      values: outputs,
      normalizedInputs: Map.unmodifiable(normalizedInputs),
      interpretation: interpretation,
      recommendations: List.unmodifiable(recommendations),
      warnings: List.unmodifiable(warnings),
      checklist: checklist,
    );
  }

  Object? _expression(
    ClinicalToolExpression expression,
    Map<String, Object?> values,
  ) {
    List<Object?> args() => expression.args
        .map((item) => _expression(item, values))
        .toList(growable: false);
    switch (expression.op) {
      case 'literal':
        return expression.value;
      case 'field':
        return values[expression.field];
      case 'add':
        return args().fold<double>(0, (sum, value) => sum + _number(value));
      case 'subtract':
        final value = args();
        return _number(value[0]) - _number(value[1]);
      case 'multiply':
        return args().fold<double>(
          1,
          (product, value) => product * _number(value),
        );
      case 'divide':
        final value = args();
        final divisor = _number(value[1]);
        if (divisor == 0) throw const FormatException('Division by zero');
        return _number(value[0]) / divisor;
      case 'power':
        final value = args();
        return math.pow(_number(value[0]), _number(value[1])).toDouble();
      case 'min':
        return args().map(_number).reduce(math.min);
      case 'max':
        return args().map(_number).reduce(math.max);
      case 'abs':
        return _number(_expression(expression.args.first, values)).abs();
      case 'greater_than':
        final value = args();
        return _number(value[0]) > _number(value[1]);
      case 'greater_than_or_equal':
        final value = args();
        return _number(value[0]) >= _number(value[1]);
      case 'less_than':
        final value = args();
        return _number(value[0]) < _number(value[1]);
      case 'less_than_or_equal':
        final value = args();
        return _number(value[0]) <= _number(value[1]);
      case 'equal':
        final value = args();
        return value[0] == value[1];
      case 'not_equal':
        final value = args();
        return value[0] != value[1];
      case 'and':
        return expression.args.every(
          (item) => _truth(_expression(item, values)),
        );
      case 'or':
        return expression.args.any((item) => _truth(_expression(item, values)));
      case 'not':
        return !_truth(_expression(expression.args.first, values));
      case 'if':
        return _truth(_expression(expression.args[0], values))
            ? _expression(expression.args[1], values)
            : _expression(expression.args[2], values);
      case 'in':
        final value = args();
        return value.skip(1).contains(value.first);
      case 'round':
        final value = _number(_expression(expression.args.first, values));
        final scale = math.pow(10, expression.precision ?? 0);
        return (value * scale).round() / scale;
      case 'now':
        return (fixedNow ?? DateTime.now()).toUtc().toIso8601String();
      case 'date_difference':
        final value = args();
        final from = DateTime.parse(value[0].toString()).toUtc();
        final to = DateTime.parse(value[1].toString()).toUtc();
        final difference = to.difference(from);
        return switch (expression.dateUnit) {
          'minutes' => difference.inMinutes,
          'hours' => difference.inHours,
          'weeks' => difference.inDays / 7,
          'months' => difference.inDays / 30.436875,
          'years' => difference.inDays / 365.2425,
          _ => difference.inDays,
        };
      case 'convert_unit':
        return _convert(
          _number(_expression(expression.args.first, values)),
          expression.fromUnit ?? '',
          expression.toUnit ?? '',
        );
      default:
        throw UnsupportedError(
          'Unsupported clinical tool operation: ${expression.op}',
        );
    }
  }

  double _number(Object? value) {
    if (value is num) return value.toDouble();
    throw const FormatException('Expected a numeric value');
  }

  bool _truth(Object? value) => value == true;

  void _appendUnique(List<String> target, Iterable<String> values) {
    for (final value in values) {
      if (!target.contains(value)) target.add(value);
    }
  }

  double _convert(double value, String from, String to) {
    if (from.isEmpty || to.isEmpty || from == to) return value;
    const factors = <String, double>{
      'kg': 1,
      'g': 0.001,
      'mg': 0.000001,
      'mcg': 0.000000001,
      'lb': 0.45359237,
      'm': 1,
      'cm': 0.01,
      'mm': 0.001,
      'in': 0.0254,
      'ft': 0.3048,
      'L': 1,
      'mL': 0.001,
      'weeks': 10080,
      'days': 1440,
      'hours': 60,
      'minutes': 1,
    };
    if (from == 'celsius' && to == 'fahrenheit') return value * 9 / 5 + 32;
    if (from == 'fahrenheit' && to == 'celsius') return (value - 32) * 5 / 9;
    final source = factors[from];
    final target = factors[to];
    if (source == null || target == null) {
      throw FormatException('Unsupported unit conversion: $from to $to');
    }
    return value * source / target;
  }
}
