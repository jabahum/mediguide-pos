import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';

final class CalculatorReviewPreview {
  const CalculatorReviewPreview({
    required this.calculatorId,
    required this.versionId,
    required this.toolName,
    required this.semanticVersion,
    required this.status,
    required this.definitionChecksum,
    required this.definition,
    required this.reviewEvidenceStatus,
    required this.raw,
  });

  factory CalculatorReviewPreview.fromJson(Map<String, dynamic> json) {
    final version = Map<String, dynamic>.from(
      json['version'] as Map? ?? const {},
    );
    return CalculatorReviewPreview(
      calculatorId: version['calculator_id']?.toString() ?? '',
      versionId: version['id']?.toString() ?? '',
      toolName: json['tool_name']?.toString() ?? '',
      semanticVersion: version['semantic_version']?.toString() ?? '',
      status: version['status']?.toString() ?? '',
      definitionChecksum: version['definition_checksum']?.toString() ?? '',
      definition: ClinicalToolDefinition.fromJson(
        Map<String, dynamic>.from(version['definition'] as Map? ?? const {}),
      ),
      reviewEvidenceStatus:
          json['review_evidence_status']?.toString() ?? 'unknown',
      raw: json,
    );
  }

  final String calculatorId;
  final String versionId;
  final String toolName;
  final String semanticVersion;
  final String status;
  final String definitionChecksum;
  final ClinicalToolDefinition definition;
  final String reviewEvidenceStatus;
  final Map<String, dynamic> raw;
}

final class CalculatorReviewRepository {
  CalculatorReviewRepository(
    this._api,
    this._cache, {
    required this.reviewerId,
    this.cacheTtl = const Duration(minutes: 30),
  });

  static const _previewType = 'calculator_review_preview';
  static const _indexType = 'calculator_review_preview_index';

  final BackendApiService _api;
  final LocalCacheService _cache;
  final String reviewerId;
  final Duration cacheTtl;

  String get _scope {
    final value = reviewerId.trim();
    if (value.isEmpty) {
      throw StateError('An authenticated reviewer is required');
    }
    return 'user:$value';
  }

  Future<CalculatorReviewPreview> preview(String versionId) async {
    final normalized = versionId.trim();
    if (normalized.isEmpty) throw ArgumentError('Version ID is required');
    try {
      final response = await _api.requestJson(
        '/api/v2/calculator-versions/${Uri.encodeComponent(normalized)}/preview',
        method: 'GET',
      );
      final data = Map<String, dynamic>.from(
        response['data'] as Map? ?? response,
      );
      final generated = ServicesCalculatorVersionPreviewDTO.fromJson(data);
      final value = CalculatorReviewPreview.fromJson(generated.toJson());
      if (value.versionId != normalized || value.definitionChecksum.isEmpty) {
        throw const FormatException('Reviewer preview identity is invalid');
      }
      final cacheId = _cacheId(value.versionId, value.definitionChecksum);
      await _cache.put(
        type: _previewType,
        id: cacheId,
        data: data,
        scope: _scope,
        ttl: cacheTtl,
      );
      await _cache.put(
        type: _indexType,
        id: value.versionId,
        data: {'cache_id': cacheId, 'checksum': value.definitionChecksum},
        scope: _scope,
        ttl: cacheTtl,
      );
      return value;
    } catch (_) {
      final cached = await _cached(normalized);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> addComment(String versionId, String comment) async {
    final normalized = comment.trim();
    if (normalized.isEmpty) throw ArgumentError('Review comment is required');
    await _api.requestJson(
      '/api/v2/calculator-versions/${Uri.encodeComponent(versionId)}/review-comments',
      method: 'POST',
      body: {'comment': normalized},
    );
  }

  Future<CalculatorReviewPreview?> _cached(String versionId) async {
    final index = await _cache.getEntry(
      type: _indexType,
      id: versionId,
      scope: _scope,
    );
    if (!_usable(index)) {
      await _cache.remove(type: _indexType, id: versionId, scope: _scope);
      return null;
    }
    final cacheId = index!.data['cache_id']?.toString() ?? '';
    final checksum = index.data['checksum']?.toString() ?? '';
    if (cacheId != _cacheId(versionId, checksum)) return null;
    final entry = await _cache.getEntry(
      type: _previewType,
      id: cacheId,
      scope: _scope,
    );
    if (!_usable(entry)) {
      await _cache.remove(type: _previewType, id: cacheId, scope: _scope);
      await _cache.remove(type: _indexType, id: versionId, scope: _scope);
      return null;
    }
    final value = CalculatorReviewPreview.fromJson(entry!.data);
    if (value.versionId != versionId || value.definitionChecksum != checksum) {
      return null;
    }
    return value;
  }

  bool _usable(CachedEntityValue? entry) {
    if (entry == null || entry.isDeleted) return false;
    final expiresAt = entry.expiresAt;
    return expiresAt == null || expiresAt.isAfter(DateTime.now().toUtc());
  }

  String _cacheId(String versionId, String checksum) => '$versionId:$checksum';
}
