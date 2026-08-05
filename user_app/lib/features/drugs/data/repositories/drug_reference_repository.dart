import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';
import 'package:user_app/features/drugs/data/models/drug_category.dart';
import 'package:user_app/features/drugs/data/models/drug_class.dart';
import 'package:user_app/features/drugs/data/models/drug_tag.dart';
import 'package:user_app/features/drugs/data/models/therapeutic_category.dart';

final class DrugReferenceRepository {
  DrugReferenceRepository(this._api, {TtlResponseCache? cache})
    : _cache = cache ?? TtlResponseCache();
  final BackendApiService _api;
  final TtlResponseCache _cache;

  Future<List<DrugCategory>> categories() =>
      _items('/api/v2/drug-categories', DrugCategory.fromJson);
  Future<List<DrugTag>> tags() => _items('/api/v2/drug-tags', DrugTag.fromJson);
  Future<List<DrugClass>> classes() =>
      _items('/api/v2/drug-classes', DrugClass.fromJson);
  Future<List<TherapeuticCategory>> therapeuticCategories() =>
      _items('/api/v2/therapeutic-categories', TherapeuticCategory.fromJson);

  Future<List<String>> categoryNames() async =>
      (await categories()).map((item) => item.name).toList(growable: false);
  Future<List<String>> tagNames() async =>
      (await tags()).map((item) => item.name).toList(growable: false);

  Future<List<T>> _items<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _cache.getOrLoad(
      key: 'drug-reference:$path',
      ttl: const Duration(minutes: 30),
      load: () => _api.requestJson(
        path,
        method: 'GET',
        query: const {
          'page': '1',
          'per_page': '100',
          'sort': 'name',
          'order': 'asc',
        },
      ),
    );
    final value = response['data'] is Map ? response['data'] : response;
    final items = value is Map ? value['items'] : null;
    return (items as List? ?? const [])
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
