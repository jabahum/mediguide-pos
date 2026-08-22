import 'dart:convert';

import 'package:user_app/app/router/route_names.dart';

final class NotificationActionTarget {
  const NotificationActionTarget.internal(this.location) : externalUri = null;
  const NotificationActionTarget.external(this.externalUri) : location = null;

  final String? location;
  final Uri? externalUri;
}

abstract final class NotificationActionResolver {
  static const Set<String> _internalRoutes = {
    AppRoutes.main,
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.guidelines,
    AppRoutes.publicGuidelines,
    AppRoutes.tools,
    AppRoutes.profile,
    AppRoutes.library,
    AppRoutes.offlineContent,
    AppRoutes.outbreakHub,
    AppRoutes.situationReports,
    AppRoutes.drugIndex,
    AppRoutes.abbreviations,
    AppRoutes.healthInfrastructure,
    AppRoutes.healthFacilities,
    AppRoutes.consultants,
    AppRoutes.ministryDirectory,
    AppRoutes.calculators,
    AppRoutes.aiAssistant,
    AppRoutes.chatList,
    AppRoutes.allActions,
    AppRoutes.notifications,
    AppRoutes.helpCenter,
    AppRoutes.faq,
    AppRoutes.aboutUs,
    AppRoutes.termsAndConditions,
  };

  static const Set<String> _approvedExternalHosts = {
    'mediguide.health.go.ug',
    'health.go.ug',
    'www.health.go.ug',
    'who.int',
    'www.who.int',
    'afro.who.int',
    'www.afro.who.int',
    'iris.who.int',
  };

  static const Set<String> _reservedParameters = {
    'redirect',
    'redirect_uri',
    'redirect_url',
    'return_to',
    'return_url',
    'next',
    'url',
    'uri',
    'deeplink',
  };

  static NotificationActionTarget? fromPushData(Map<String, dynamic> data) {
    Map<String, dynamic>? action;
    final encoded = data['action'];
    if (encoded is String && encoded.isNotEmpty) {
      try {
        action = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
      } catch (_) {}
    } else if (encoded is Map) {
      action = Map<String, dynamic>.from(encoded);
    }

    action ??= <String, dynamic>{
      if (data['action_type'] != null) 'type': data['action_type'],
      if (data['resource_id'] != null) 'resource_id': data['resource_id'],
      if (data['route'] != null) 'route': data['route'],
      'parameters': _decodeParameters(data['action_parameters']),
    };
    return resolve(
      action: action,
      legacyActionUrl: data['action_url']?.toString(),
    );
  }

  /// Resolves a published outbreak resource through the same allowlisted
  /// navigation boundary used by notifications. Unknown or malformed resource
  /// types deliberately resolve to null instead of falling back to a raw URL.
  static NotificationActionTarget? fromOutbreakResource({
    required String type,
    required String url,
    required String assetUrl,
  }) {
    final normalized = type.trim();
    final raw = url.trim();
    switch (normalized) {
      case 'guideline':
        final uri = Uri.tryParse(raw);
        final segments = uri?.pathSegments ?? const <String>[];
        if (uri == null ||
            uri.hasScheme ||
            uri.hasAuthority ||
            uri.queryParameters.isNotEmpty ||
            uri.fragment.isNotEmpty ||
            segments.length != 3 ||
            segments[0] != 'public' ||
            segments[1] != 'guidelines' ||
            !_validUUID(segments[2])) {
          return null;
        }
        return resolve(
          action: {
            'type': 'guideline',
            'resource_id': segments[2],
            'parameters': const <String, String>{},
          },
        );
      case 'situation_report':
        final uri = Uri.tryParse(raw);
        final segments = uri?.pathSegments ?? const <String>[];
        if (uri == null ||
            uri.hasScheme ||
            uri.hasAuthority ||
            uri.queryParameters.isNotEmpty ||
            uri.fragment.isNotEmpty ||
            segments.length != 2 ||
            segments[0] != 'situation-reports' ||
            !_validUUID(segments[1])) {
          return null;
        }
        return resolve(
          action: {
            'type': 'situation_report',
            'resource_id': segments[1],
            'parameters': const <String, String>{},
          },
        );
      case 'internal_route':
        return resolve(
          action: {
            'type': 'internal_route',
            'route': raw,
            'parameters': const <String, String>{},
          },
        );
      case 'approved_external_url':
      case 'official_statement':
      case 'official_update':
      case 'link':
        return resolve(
          action: {
            'type': 'approved_external_url',
            'route': raw,
            'parameters': const <String, String>{},
          },
        );
      case 'managed_document':
      case 'downloadable_asset':
        final managed = assetUrl.trim();
        return resolve(
          action: {
            'type': 'approved_external_url',
            'route': managed,
            'parameters': const <String, String>{},
          },
        );
      default:
        return null;
    }
  }

  static NotificationActionTarget? resolve({
    Map<String, dynamic>? action,
    String? legacyActionUrl,
  }) {
    final type = action?['type']?.toString().trim() ?? '';
    if (type.isEmpty) return _legacy(legacyActionUrl);
    if (type == 'none') return null;

    final resourceId = action?['resource_id']?.toString().trim();
    final parameters = _stringParameters(action?['parameters']);
    String? location;
    switch (type) {
      case 'guideline':
        if (!_validUUID(resourceId)) return null;
        location = AppRoutes.publicGuideline(resourceId!);
        break;
      case 'outbreak':
        if (!_validUUID(resourceId)) return null;
        location = AppRoutes.outbreak(resourceId!);
        break;
      case 'situation_report':
        if (!_validUUID(resourceId)) return null;
        location = AppRoutes.situationReport(resourceId!);
        break;
      case 'drug':
        if (!_validUUID(resourceId)) return null;
        location = AppRoutes.drugIndex;
        parameters['drug_id'] = resourceId!;
        break;
      case 'calculator':
        if (!_validUUID(resourceId)) return null;
        location = AppRoutes.calculator(resourceId!);
        break;
      case 'facility':
        if (!_validUUID(resourceId)) return null;
        location = AppRoutes.healthFacility(resourceId!);
        break;
      case 'support_ticket':
        if (!_validUUID(resourceId)) return null;
        location = AppRoutes.helpCenter;
        parameters['ticket_id'] = resourceId!;
        break;
      case 'internal_route':
        final route = action?['route']?.toString().trim();
        if (!_validInternalRoute(route)) return null;
        location = route;
        break;
      case 'approved_external_url':
        final uri = Uri.tryParse(action?['route']?.toString().trim() ?? '');
        return _validExternal(uri)
            ? NotificationActionTarget.external(uri)
            : null;
      default:
        return null;
    }

    final uri = Uri.parse(location!);
    final query = <String, String>{...uri.queryParameters, ...parameters};
    return NotificationActionTarget.internal(
      uri.replace(queryParameters: query.isEmpty ? null : query).toString(),
    );
  }

  static NotificationActionTarget? _legacy(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final external = Uri.tryParse(raw);
    if (_validExternal(external)) {
      return NotificationActionTarget.external(external);
    }
    if (_validInternalRoute(raw)) {
      return NotificationActionTarget.internal(raw);
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    final segments = uri.pathSegments;
    if (segments.length == 3 &&
        segments[0] == 'public' &&
        segments[1] == 'guidelines' &&
        _validUUID(segments[2])) {
      return NotificationActionTarget.internal(raw);
    }
    return null;
  }

  static bool _validInternalRoute(String? value) {
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null &&
        !uri.hasScheme &&
        !uri.hasAuthority &&
        uri.queryParameters.isEmpty &&
        uri.fragment.isEmpty &&
        _internalRoutes.contains(uri.path);
  }

  static bool _validExternal(Uri? uri) =>
      uri != null &&
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      _approvedExternalHosts.contains(uri.host.toLowerCase());

  static bool _validUUID(String? value) {
    if (value == null) return false;
    final parts = value.split('-');
    const lengths = <int>[8, 4, 4, 4, 12];
    if (parts.length != lengths.length) return false;
    for (var index = 0; index < parts.length; index++) {
      if (parts[index].length != lengths[index] ||
          int.tryParse(parts[index], radix: 16) == null) {
        return false;
      }
    }
    return true;
  }

  static bool _validParameterKey(String value) {
    if (value.isEmpty || value.length > 64) return false;
    for (final code in value.codeUnits) {
      final valid =
          (code >= 48 && code <= 57) ||
          (code >= 65 && code <= 90) ||
          (code >= 97 && code <= 122) ||
          code == 95 ||
          code == 46 ||
          code == 45;
      if (!valid) return false;
    }
    return true;
  }

  static Map<String, String> _decodeParameters(dynamic value) {
    if (value is! String || value.isEmpty) return <String, String>{};
    try {
      return _stringParameters(jsonDecode(value));
    } catch (_) {
      return <String, String>{};
    }
  }

  static Map<String, String> _stringParameters(dynamic value) {
    if (value is! Map) return <String, String>{};
    final result = <String, String>{};
    for (final entry in value.entries.take(20)) {
      final key = entry.key.toString();
      final item = entry.value?.toString() ?? '';
      if (_validParameterKey(key) &&
          !_reservedParameters.contains(key.toLowerCase()) &&
          item.length <= 512) {
        result[key] = item;
      }
    }
    return result;
  }
}
