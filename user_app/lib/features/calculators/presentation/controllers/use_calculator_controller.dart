import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';
import 'package:user_app/shared/models/models.dart';

part 'use_calculator_controller.g.dart';

/// ======================================================
/// REQUEST
/// ======================================================

final class UseCalculatorRequest {
  const UseCalculatorRequest({required this.id, this.calculator});

  final String id;
  final Calculator? calculator;

  @override
  bool operator ==(Object other) {
    return other is UseCalculatorRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// ======================================================
/// CONTENT
/// ======================================================

final class CalculatorContent {
  const CalculatorContent({required this.html, required this.baseUrl});

  final String html;
  final String baseUrl;
}

abstract interface class CalculatorContentLoader {
  Future<CalculatorContent> load(Calculator calculator);
}

/// ======================================================
/// CONTENT LOADER PROVIDER
/// ======================================================

@riverpod
CalculatorContentLoader calculatorContentLoader(Ref ref) {
  return FileCalculatorContentLoader(ref.watch(calculatorRepositoryProvider));
}

/// ======================================================
/// FILE CONTENT LOADER
/// ======================================================

final class FileCalculatorContentLoader implements CalculatorContentLoader {
  FileCalculatorContentLoader(this._repository);

  final CalculatorRepository _repository;

  @override
  Future<CalculatorContent> load(Calculator calculator) async {
    if (calculator.appFile.isEmpty) {
      throw StateError('Calculator file not found');
    }

    final directory = await getApplicationDocumentsDirectory();

    final htmlFile = File('${directory.path}/calculator_${calculator.id}.html');

    final metadataFile = File(
      '${directory.path}/calculator_${calculator.id}.json',
    );

    final downloadUrl = _repository.contentUrl(calculator.id);

    const baseUrl = 'https://legacy-tools.invalid/';

    String? fallback;

    // ------------------------------------------------------
    // CACHE
    // ------------------------------------------------------

    if (await htmlFile.exists()) {
      final cached = await htmlFile.readAsString();

      if (cached.trim().startsWith('<') && legacyCalculatorCacheValid(cached)) {
        fallback = cached;

        final metadata = await _metadata(metadataFile);

        final cacheIsCurrent =
            metadata?['version']?.toString() == calculator.version &&
            metadata?['appFile']?.toString() == calculator.appFile &&
            metadata?['downloadUrl']?.toString() == downloadUrl &&
            metadata?['sha256']?.toString() ==
                legacyCalculatorCacheDigest(cached);

        if (cacheIsCurrent) {
          return CalculatorContent(html: cached, baseUrl: baseUrl);
        }
      } else {
        await htmlFile.delete();

        if (await metadataFile.exists()) {
          await metadataFile.delete();
        }
      }
    }

    // ------------------------------------------------------
    // NETWORK
    // ------------------------------------------------------

    try {
      final html = await _repository.content(calculator.id);

      if (!html.trim().startsWith('<')) {
        throw const FormatException('Invalid calculator HTML');
      }

      if (!legacyCalculatorCacheValid(html)) {
        throw const FormatException(
          'Calculator HTML exceeds the contained artifact limit',
        );
      }

      await htmlFile.writeAsString(html);

      await metadataFile.writeAsString(
        jsonEncode({
          'version': calculator.version,
          'appFile': calculator.appFile,
          'downloadUrl': downloadUrl,
          'sha256': legacyCalculatorCacheDigest(html),
        }),
      );

      return CalculatorContent(html: html, baseUrl: baseUrl);
    } catch (_) {
      // Use stale cached calculator if the network
      // version cannot be fetched.
      if (fallback != null) {
        return CalculatorContent(html: fallback, baseUrl: baseUrl);
      }

      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _metadata(File file) async {
    if (!await file.exists()) {
      return null;
    }

    try {
      final value = jsonDecode(await file.readAsString());

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

const int _maxLegacyCalculatorBytes = 256 << 10;

@visibleForTesting
String legacyCalculatorCacheDigest(String html) =>
    sha256.convert(utf8.encode(html)).toString();

@visibleForTesting
bool legacyCalculatorCacheValid(String html) =>
    html.trimLeft().startsWith('<') &&
    utf8.encode(html).length <= _maxLegacyCalculatorBytes;

/// ======================================================
/// STATE
/// ======================================================

final class UseCalculatorState {
  const UseCalculatorState({
    required this.calculator,
    this.html = '',
    this.baseUrl = '',
    this.definition,
    this.responses = const {},
    this.isWebViewReady = false,
    this.webViewError,
  });

  final Calculator calculator;
  final String html;
  final String baseUrl;
  final ClinicalToolDefinitionEnvelope? definition;
  final Map<String, Object?> responses;

  final bool isWebViewReady;
  final String? webViewError;

  UseCalculatorState copyWith({
    Map<String, Object?>? responses,
    bool? isWebViewReady,
    String? webViewError,
    bool clearError = false,
  }) {
    return UseCalculatorState(
      calculator: calculator,
      html: html,
      baseUrl: baseUrl,
      definition: definition,
      responses: responses ?? this.responses,
      isWebViewReady: isWebViewReady ?? this.isWebViewReady,
      webViewError: clearError ? null : webViewError ?? this.webViewError,
    );
  }
}

/// ======================================================
/// CONTROLLER
/// ======================================================

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

    ref.onDispose(() {
      unawaited(_finishUsage());
    });

    if (calculator.isNativeSchema) {
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

    final content = await ref
        .read(calculatorContentLoaderProvider)
        .load(calculator);

    return UseCalculatorState(
      calculator: calculator,
      html: content.html,
      baseUrl: content.baseUrl,
    );
  }

  Future<void> saveResponses(Map<String, Object?> responses) async {
    final current = state.valueOrNull;
    final userId = ref.read(authControllerProvider).valueOrNull?.user?.id;
    if (current?.definition == null ||
        userId == null ||
        !current!.definition!.definition.completion.allowResume) {
      return;
    }
    await _repository.saveWorkflow(
      calculatorId: current.calculator.id,
      userId: userId,
      definition: current.definition!,
      responses: responses,
    );
    state = AsyncData(
      current.copyWith(responses: Map<String, Object?>.from(responses)),
    );
  }

  /// ======================================================
  /// WEBVIEW
  /// ======================================================

  void webViewLoading() {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(isWebViewReady: false, clearError: true),
    );
  }

  void webViewReady() {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(isWebViewReady: true, clearError: true));
  }

  void webViewFailed(String message) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(isWebViewReady: false, webViewError: message),
    );
  }

  /// ======================================================
  /// RELOAD
  /// ======================================================

  Future<void> reload() async {
    ref.invalidateSelf();

    await future;
  }

  /// ======================================================
  /// USAGE TRACKING
  /// ======================================================

  Future<void> _startUsage(Calculator calculator) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      return;
    }

    try {
      _sessionStart = DateTime.now().toUtc();

      final record = await _repository.startUsage(
        calculatorId: calculator.id,
        sessionStart: _sessionStart!.toIso8601String(),
        calculatorType: _calculatorTypeValue(calculator.type),
      );

      _usageId = record.id;
    } catch (_) {
      // Analytics must never block calculator usage.
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

    if (start == null || usageId == null) {
      return;
    }

    final end = DateTime.now().toUtc();

    if (end.difference(start).inSeconds < 5) {
      return;
    }

    try {
      await _repository.finishUsage(
        usageId: usageId,
        sessionEnd: end.toIso8601String(),
      );
    } catch (_) {
      // Analytics failure is intentionally non-blocking.
    }
  }

  String _calculatorTypeValue(CalculatorType type) {
    return switch (type) {
      CalculatorType.calculator => 'calculator',
      CalculatorType.decisionTool => 'decision_tool',
      CalculatorType.checklist => 'checklist',
    };
  }
}
