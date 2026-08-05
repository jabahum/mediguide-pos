import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

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

final class CalculatorContent {
  const CalculatorContent({required this.html, required this.baseUrl});
  final String html;
  final String baseUrl;
}

abstract interface class CalculatorContentLoader {
  Future<CalculatorContent> load(Calculator calculator);
}

final calculatorContentLoaderProvider = Provider<CalculatorContentLoader>(
  (ref) => FileCalculatorContentLoader(ref.watch(calculatorRepositoryProvider)),
);

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
    final baseUrl = _baseUrl(downloadUrl);
    String? fallback;

    if (await htmlFile.exists()) {
      final cached = await htmlFile.readAsString();
      if (cached.trim().startsWith('<')) {
        fallback = cached;
        final metadata = await _metadata(metadataFile);
        if (metadata?['version']?.toString() == calculator.version &&
            metadata?['appFile']?.toString() == calculator.appFile &&
            metadata?['downloadUrl']?.toString() == downloadUrl) {
          return CalculatorContent(html: cached, baseUrl: baseUrl);
        }
      } else {
        await htmlFile.delete();
        if (await metadataFile.exists()) await metadataFile.delete();
      }
    }

    try {
      final html = await _repository.content(calculator.id);
      if (!html.trim().startsWith('<')) {
        throw const FormatException('Invalid calculator HTML');
      }
      await htmlFile.writeAsString(html);
      await metadataFile.writeAsString(
        jsonEncode({
          'version': calculator.version,
          'appFile': calculator.appFile,
          'downloadUrl': downloadUrl,
        }),
      );
      return CalculatorContent(html: html, baseUrl: baseUrl);
    } catch (_) {
      if (fallback != null) {
        return CalculatorContent(html: fallback, baseUrl: baseUrl);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _metadata(File file) async {
    if (!await file.exists()) return null;
    try {
      final value = jsonDecode(await file.readAsString());
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } catch (_) {
      return null;
    }
  }

  String _baseUrl(String downloadUrl) {
    final uri = Uri.parse(downloadUrl);
    final segments = uri.pathSegments.toList();
    if (segments.isEmpty) return mediguideApiBaseUrl;
    segments.removeLast();
    return uri
        .replace(
          path: segments.isEmpty ? '/' : '/${segments.join('/')}',
          query: null,
          fragment: null,
        )
        .toString();
  }
}

final class UseCalculatorState {
  const UseCalculatorState({
    required this.calculator,
    required this.html,
    required this.baseUrl,
    this.isWebViewReady = false,
    this.webViewError,
  });

  final Calculator calculator;
  final String html;
  final String baseUrl;
  final bool isWebViewReady;
  final String? webViewError;

  UseCalculatorState copyWith({
    bool? isWebViewReady,
    String? webViewError,
    bool clearError = false,
  }) => UseCalculatorState(
    calculator: calculator,
    html: html,
    baseUrl: baseUrl,
    isWebViewReady: isWebViewReady ?? this.isWebViewReady,
    webViewError: clearError ? null : webViewError ?? this.webViewError,
  );
}

final useCalculatorControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      UseCalculatorController,
      UseCalculatorState,
      UseCalculatorRequest
    >(UseCalculatorController.new);

class UseCalculatorController
    extends
        AutoDisposeFamilyAsyncNotifier<
          UseCalculatorState,
          UseCalculatorRequest
        > {
  DateTime? _sessionStart;
  String? _usageId;
  Future<void>? _usageStart;
  late CalculatorRepository _repository;

  @override
  Future<UseCalculatorState> build(UseCalculatorRequest request) async {
    _repository = ref.read(calculatorRepositoryProvider);
    if (request.id.isEmpty) {
      throw ArgumentError.value(request.id, 'calculatorId', 'is required');
    }
    final calculator =
        request.calculator ??
        Calculator.fromRecord(await _repository.get(request.id));
    _usageStart = _startUsage(calculator);
    ref.onDispose(() => unawaited(_finishUsage()));
    final content = await ref
        .read(calculatorContentLoaderProvider)
        .load(calculator);
    return UseCalculatorState(
      calculator: calculator,
      html: content.html,
      baseUrl: content.baseUrl,
    );
  }

  void webViewLoading() {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncData(
        value.copyWith(isWebViewReady: false, clearError: true),
      );
    }
  }

  void webViewReady() {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncData(value.copyWith(isWebViewReady: true, clearError: true));
    }
  }

  void webViewFailed(String message) {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncData(
        value.copyWith(isWebViewReady: false, webViewError: message),
      );
    }
  }

  Future<void> _startUsage(Calculator calculator) async {
    if (ref.read(authControllerProvider).valueOrNull?.user == null) return;
    try {
      _sessionStart = DateTime.now().toUtc();
      final record = await _repository.startUsage(
        calculatorId: calculator.id,
        sessionStart: _sessionStart!.toIso8601String(),
        calculatorType: switch (calculator.type) {
          CalculatorType.calculator => 'calculator',
          CalculatorType.decisionTool => 'decision_tool',
          CalculatorType.checklist => 'checklist',
        },
      );
      _usageId = record.id;
    } catch (_) {
      // Analytics must not block calculator usage.
    }
  }

  Future<void> _finishUsage() async {
    await _usageStart;
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
      // Analytics failure is intentionally non-blocking.
    }
  }
}
