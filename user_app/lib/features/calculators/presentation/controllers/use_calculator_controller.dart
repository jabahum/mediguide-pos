import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/shared/models/models.dart';

part 'use_calculator_controller.g.dart';

final class UseCalculatorRequest {
  const UseCalculatorRequest({required this.id, this.calculator});
  final String id;
  final Calculator? calculator;
  @override
  bool operator ==(Object other) =>
      other is UseCalculatorRequest && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

final class UseCalculatorState {
  const UseCalculatorState({
    required this.calculator,
    required this.definition,
    this.responses = const {},
  });
  final Calculator calculator;
  final ClinicalToolDefinitionEnvelope definition;
  final Map<String, Object?> responses;
  UseCalculatorState copyWith({Map<String, Object?>? responses}) =>
      UseCalculatorState(
        calculator: calculator,
        definition: definition,
        responses: responses ?? this.responses,
      );
}

@riverpod
class UseCalculatorController extends _$UseCalculatorController {
  DateTime? _sessionStart;
  String? _usageId;
  Future<void>? _usageStart;
  CalculatorRepository get _repository =>
      ref.read(calculatorRepositoryProvider);

  @override
  Future<UseCalculatorState> build(UseCalculatorRequest request) async {
    if (request.id.trim().isEmpty) {
      throw ArgumentError.value(request.id, 'calculatorId', 'is required');
    }
    final calculator = request.calculator ?? await _repository.get(request.id);
    _usageStart = _startUsage(calculator);
    ref.onDispose(() => unawaited(_finishUsage()));

    // A published schema is now the only executable clinical-tool runtime.
    // The repository may return a checksum-validated cached definition offline.
    final definition = await _repository.definition(calculator.id);
    final userId = ref.read(authControllerProvider).valueOrNull?.user?.id;
    final responses =
        userId == null || !definition.definition.completion.allowResume
        ? const <String, Object?>{}
        : await _repository.workflow(
            calculatorId: calculator.id,
            userId: userId,
            definition: definition,
          );
    return UseCalculatorState(
      calculator: calculator,
      definition: definition,
      responses: responses,
    );
  }

  Future<void> saveResponses(Map<String, Object?> responses) async {
    final current = state.valueOrNull;
    final userId = ref.read(authControllerProvider).valueOrNull?.user?.id;
    if (current == null ||
        userId == null ||
        !current.definition.definition.completion.allowResume) {
      return;
    }
    await _repository.saveWorkflow(
      calculatorId: current.calculator.id,
      userId: userId,
      definition: current.definition,
      responses: responses,
    );
    state = AsyncData(
      current.copyWith(responses: Map<String, Object?>.from(responses)),
    );
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> _startUsage(Calculator calculator) async {
    if (ref.read(authControllerProvider).valueOrNull?.user == null) return;
    try {
      _sessionStart = DateTime.now().toUtc();
      final record = await _repository.startUsage(
        calculatorId: calculator.id,
        sessionStart: _sessionStart!.toIso8601String(),
        calculatorType: _calculatorTypeValue(calculator.type),
      );
      _usageId = record.id;
    } catch (_) {
      /* Analytics must never block tool use. */
    }
  }

  Future<void> _finishUsage() async {
    try {
      await _usageStart;
    } catch (_) {
      return;
    }
    final start = _sessionStart;
    final usageId = _usageId;
    if (start == null || usageId == null) return;
    final end = DateTime.now().toUtc();
    if (end.difference(start).inSeconds < 5) return;
    try {
      await _repository.finishUsage(
        usageId: usageId,
        sessionEnd: end.toIso8601String(),
      );
    } catch (_) {
      /* Non-blocking analytics. */
    }
  }

  String _calculatorTypeValue(CalculatorType type) => switch (type) {
    CalculatorType.calculator => 'calculator',
    CalculatorType.decisionTool => 'decision_tool',
    CalculatorType.checklist => 'checklist',
  };
}
