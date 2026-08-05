import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class TtlResponseCache {
  TtlResponseCache({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _prefix = 'mediguide.reference-cache.v1.';
  SharedPreferences? _preferences;

  Future<Map<String, dynamic>> getOrLoad({
    required String key,
    required Duration ttl,
    required Future<Map<String, dynamic>> Function() load,
  }) async {
    final entry = await _read(key);
    if (entry != null && DateTime.now().difference(entry.cachedAt) <= ttl) {
      return entry.data;
    }
    if (entry != null) {
      unawaited(_refresh(key, load));
      return entry.data;
    }
    final value = await load();
    await _write(key, value);
    return value;
  }

  Future<void> _refresh(
    String key,
    Future<Map<String, dynamic>> Function() load,
  ) async {
    try {
      await _write(key, await load());
    } catch (_) {
      // Stale reference data remains usable while the device is offline.
    }
  }

  Future<_CacheEntry?> _read(String key) async {
    try {
      final raw = (await _prefs).getString(_storageKey(key));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final value = Map<String, dynamic>.from(decoded);
      final cachedAt = DateTime.tryParse(value['cached_at']?.toString() ?? '');
      final data = value['data'];
      if (cachedAt == null || data is! Map) return null;
      return _CacheEntry(cachedAt, Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Map<String, dynamic> data) async {
    try {
      await (await _prefs).setString(
        _storageKey(key),
        jsonEncode({
          'cached_at': DateTime.now().toUtc().toIso8601String(),
          'data': data,
        }),
      );
    } catch (_) {
      // Persistence is an optimization; network data remains authoritative.
    }
  }

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  String _storageKey(String key) =>
      '$_prefix${base64Url.encode(utf8.encode(key)).replaceAll('=', '')}';
}

final class _CacheEntry {
  const _CacheEntry(this.cachedAt, this.data);
  final DateTime cachedAt;
  final Map<String, dynamic> data;
}
