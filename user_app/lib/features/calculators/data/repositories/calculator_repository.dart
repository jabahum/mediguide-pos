import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';

import 'package:user_app/features/calculators/data/repositories/calculator_local_repository.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';

// ===========================================================
// CALCULATORS
// ===========================================================

final class CalculatorRepository {
  CalculatorRepository(this._api, this._local);

  final BackendApiService _api;
  final CalculatorLocalRepository _local;

  Future<PaginatedResponse<Calculator>> list({
    int page = 1,
    int perPage = 30,
    String? search,
    List<String> types = const [],
    List<String> statuses = const [],
    bool? featured,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    try {
      final response = await _api.requestJson(
        '/api/v2/calculators',
        method: 'GET',
        query: {
          'page': '$safePage',
          'per_page': '$safePerPage',
          if (_present(search)) 'search': search!.trim(),
          if (types.isNotEmpty) 'type': types.join(','),
          if (statuses.isNotEmpty) 'status': statuses.join(','),
          if (featured != null) 'featured': '$featured',
          'sort': sort,
          'order': order,
        },
      );

      final data = _data(response);

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Calculator.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      try {
        await _local.saveCalculators(items);
      } catch (_) {}

      return PaginatedResponse<Calculator>(
        items: items,
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
      );
    } catch (_) {
      final cached = await _local.getCalculators(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<Calculator>(
        items: cached,
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: _totalPages(cached.length, safePerPage),
      );
    }
  }

  Future<ClinicalToolDefinitionEnvelope> definition(String id) async {
    try {
      final response = await _api.requestJson(
        '/api/v2/calculators/${Uri.encodeComponent(id)}/definition',
        method: 'GET',
      );
      final generated = ServicesCalculatorDefinitionDTO.fromJson(
        _itemData(response),
      );
      final value = ClinicalToolDefinitionEnvelope.fromJson(generated.toJson());
      await _local.saveDefinition(value);
      return value;
    } catch (_) {
      final cached = await _local.getDefinition(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Map<String, Object?>> workflow({
    required String calculatorId,
    required String userId,
    required ClinicalToolDefinitionEnvelope definition,
  }) => _local.getWorkflow(
    calculatorId: calculatorId,
    userId: userId,
    versionId: definition.versionId,
    checksum: definition.definitionChecksum,
  );

  Future<void> saveWorkflow({
    required String calculatorId,
    required String userId,
    required ClinicalToolDefinitionEnvelope definition,
    required Map<String, Object?> responses,
  }) => _local.saveWorkflow(
    calculatorId: calculatorId,
    userId: userId,
    versionId: definition.versionId,
    checksum: definition.definitionChecksum,
    responses: responses,
  );

  // =========================================================
  // GET
  // =========================================================

  Future<Calculator> get(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Calculator id is required');
    }

    try {
      final response = await _api.requestJson(
        '/api/v2/calculators/${Uri.encodeComponent(normalizedId)}',
        method: 'GET',
      );

      final calculator = Calculator.fromJson(_itemData(response));

      try {
        await _local.saveCalculator(calculator);
      } catch (_) {}

      return calculator;
    } catch (_) {
      final cached = await _local.getCalculator(normalizedId);

      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  // =========================================================
  // USAGE
  // =========================================================
  //
  // Analytics remain non-blocking at controller level.
  // Do not make calculator availability depend on these calls.
  // =========================================================

  Future<CalculatorUsageLog> startUsage({
    required String calculatorId,
    required String sessionStart,
    required String calculatorType,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/calculators/'
      '${Uri.encodeComponent(calculatorId)}/usage',
      method: 'POST',
      body: {'session_start': sessionStart, 'calculator_type': calculatorType},
    );

    return CalculatorUsageLog.fromJson(_itemData(response));
  }

  Future<CalculatorUsageLog> finishUsage({
    required String usageId,
    required String sessionEnd,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/calculator-usage/'
      '${Uri.encodeComponent(usageId)}',
      method: 'PATCH',
      body: {'session_end': sessionEnd},
    );

    return CalculatorUsageLog.fromJson(_itemData(response));
  }
}

// ===========================================================
// SHARED RESPONSE HELPERS
// ===========================================================

Map<String, dynamic> _data(Map<String, dynamic> response) {
  return response['data'] is Map
      ? Map<String, dynamic>.from(response['data'] as Map)
      : response;
}

Map<String, dynamic> _itemData(Map<String, dynamic> response) {
  final data = _data(response);
  final item = data['item'];

  return item is Map ? Map<String, dynamic>.from(item) : data;
}

bool _present(String? value) {
  return value?.trim().isNotEmpty == true;
}

int _totalPages(int totalItems, int perPage) {
  if (totalItems <= 0 || perPage <= 0) {
    return 0;
  }

  return (totalItems / perPage).ceil();
}
